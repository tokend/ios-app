import Foundation
import TokenDSDK
import TokenDWallet
import DLCryptoKit

class BasePasswordChanger {

    // MARK: - Private properties

    private let transactionCreator: TransactionCreator
    private let keyServerApi: KeyServerApi
    private let accountsApiV3: AccountsApiV3
    private let userDataProvider: UserDataProviderProtocol
    private let keychainManager: KeychainManagerProtocol
    private let keysProvider: KeyServerAPIKeysProviderProtocol

    // MARK: -

    init(
        transactionCreator: TransactionCreator,
        keyServerApi: KeyServerApi,
        accountsApiV3: AccountsApiV3,
        userDataProvider: UserDataProviderProtocol,
        keychainManager: KeychainManagerProtocol,
        keysProvider: KeyServerAPIKeysProviderProtocol
    ) {

        self.transactionCreator = transactionCreator
        self.keyServerApi = keyServerApi
        self.accountsApiV3 = accountsApiV3
        self.userDataProvider = userDataProvider
        self.keychainManager = keychainManager
        self.keysProvider = keysProvider
    }
}

// MARK: - Private methods

private extension BasePasswordChanger {

    typealias OperationBody = TokenDWallet.Operation.OperationBody

    func requestWalletKDF(
        newPassword: String,
        oldPassword: String,
        completion: @escaping (ChangePasswordResult) -> Void
    ) {

        keyServerApi.getWalletKDF(
            login: userDataProvider.account,
            completion: { [weak self] (result) in

                switch result {

                case .success(let walletKDF):
                    self?.requestAccountSigners(
                        newPassword: newPassword,
                        oldPassword: oldPassword,
                        kdf: walletKDF,
                        completion: completion
                    )

                case .failure(let error):
                    completion(.failure(error))
                }
        })
    }

    enum RequestAccountSignersError: Swift.Error {

        case emptySignersDocument
    }
    func requestAccountSigners(
        newPassword: String,
        oldPassword: String,
        kdf: WalletKDFParams,
        completion: @escaping (ChangePasswordResult) -> Void
    ) {

        accountsApiV3.requestSigners(
            accountId: userDataProvider.walletData.accountId,
            completion: { [weak self] (result) in

                switch result {

                case .failure(let error):
                    completion(.failure(error))

                case .success(let document):
                    guard let fetchedSigners = document.data else {
                        completion(.failure(RequestAccountSignersError.emptySignersDocument))
                        return
                    }

                    self?.requestDefaultSignerRoleId(
                        newPassword: newPassword,
                        oldPassword: oldPassword,
                        kdf: kdf,
                        currentSigners: fetchedSigners,
                        completion: completion
                    )
                }
        })
    }

    func requestDefaultSignerRoleId(
        newPassword: String,
        oldPassword: String,
        kdf: WalletKDFParams,
        currentSigners: [Horizon.SignerResource],
        completion: @escaping (ChangePasswordResult) -> Void
    ) {

        let mainKey = keysProvider.mainKey
        let currentKey = keysProvider.requestSigningKey
        keyServerApi.getDefaultSignerRoleId(completion: { [weak self] (result) in

            switch result {

            case .failure(let errors):
                completion(.failure(errors))

            case .success(let response):

                let defaultRoleId: Uint64 = .init(response.roleId)
                self?.buildManageSignersTransaction(
                    for: mainKey,
                    currentKeyPair: currentKey,
                    currentSigners: currentSigners,
                    defaultRoleId: defaultRoleId,
                    completion: { [weak self] (result) in

                        switch result {

                        case .success(let transactionModel):

                            self?.createWalletInfo(
                                newPassword: newPassword,
                                oldPassword: oldPassword,
                                kdf: kdf,
                                transaction: transactionModel,
                                completion: completion
                            )

                        case .failure(let error):
                            completion(.failure(error))
                        }

                })
            }
        })
    }

    func createWalletInfo(
        newPassword: String,
        oldPassword: String,
        kdf: WalletKDFParams,
        transaction: TransactionModel,
        completion: @escaping (ChangePasswordResult) -> Void
    ) {

        let login: String = userDataProvider.userLogin
        let result = WalletInfoBuilderV2.createChangePasswordWalletInfo(
            login: login,
            newPassword: newPassword,
            kdf: kdf.kdfParams,
            keys: keysProvider.keys,
            signers: [],
            signedTransaction: transaction
        )

        switch result {

        case .failure(let error):
            completion(.failure(error))

        case .success(let model):
            sendChangePassword(
                login: login,
                oldPassword: oldPassword,
                walletKDF: kdf,
                walletInfo: model,
                completion: completion
            )
        }
    }

    func sendChangePassword(
        login: String,
        oldPassword: String,
        walletKDF: WalletKDFParams,
        walletInfo: WalletInfoModelV2,
        completion: @escaping (ChangePasswordResult) -> Void
    ) {

        let onSignRequest = JSONAPI.RequestSignerBlockCaller.getUnsafeSignRequestBlock()
        let requestSigner = JSONAPI.RequestSignerBlockCaller(
            signingKey: keysProvider.requestSigningKey,
            accountId: walletInfo.data.attributes.accountId,
            onSignRequest: onSignRequest
        )

        keyServerApi.putWallet(
            login: login,
            walletId: userDataProvider.walletId,
            signingPassword: oldPassword,
            walletKDF: walletKDF,
            walletInfo: walletInfo,
            requestSigner: requestSigner,
            completion: { [weak self] (result) in

                switch result {

                case .success:
                    self?.saveKeys()
                    completion(.success(()))
                    
                case .failure(let error):
                    
                    switch error {
                    
                    case KeyServerApi.PutWalletError.tfaFailed:
                        completion(.failure(PasswordChangerError.wrongOldPassword))

                    default:
                        completion(.failure(error))
                    }
                }
        })
    }
    
    func saveKeys() {
        let account = userDataProvider.account
        _ = keychainManager.saveKeyData(keysProvider.keys, account: account)
    }
}

// MARK: - Transaction creation

private extension BasePasswordChanger {

    enum BuildManageSignersTransactionError: Swift.Error {

        case failedToGetAccountID
    }
    func buildManageSignersTransaction(
        for newKeyPair: ECDSA.KeyData,
        currentKeyPair: ECDSA.KeyData,
        currentSigners: [Horizon.SignerResource],
        defaultRoleId: Uint64,
        completion: @escaping (Result<TransactionModel, Swift.Error>) -> Void
    ) {

        let newKeyPairAccountId = Base32Check.encode(version: .accountIdEd25519, data: newKeyPair.getPublicKeyData())
        let currentKeyPairAccountId = Base32Check.encode(version: .accountIdEd25519, data: currentKeyPair.getPublicKeyData())

        var operations: [OperationBody] = []

        operations.append(
            contentsOf: addSigners(
                newKeyPair: newKeyPair,
                currentKeyPairAccountId: currentKeyPairAccountId,
                currentSigners: currentSigners,
                defaultRoleId: defaultRoleId
            )
        )

        operations.append(
            contentsOf: removeAllOldSigners(
                from: currentSigners,
                currentKeyPairAccountId: currentKeyPairAccountId,
                newKeyPairAccountId: newKeyPairAccountId
            )
        )

        guard let sourceAccountId = AccountID(
            base32EncodedString: userDataProvider.walletData.accountId,
            expectedVersion: .accountIdEd25519
            ) else {
                completion(.failure(BuildManageSignersTransactionError.failedToGetAccountID))
                return
        }
        transactionCreator.createTransaction(
            sourceAccountId: sourceAccountId,
            operations: operations,
            sendDate: Date(),
            completion: { (result) in

                switch result {

                case .failure(let error):
                    completion(.failure(error))

                case .success(let transactionModel):

                    do {
                        try transactionModel.addSignature(signer: currentKeyPair)
                    } catch {
                        completion(.failure(error))
                        return
                    }

                    completion(.success(transactionModel))
                }
        })
    }

    func addSigners(
        newKeyPair: ECDSA.KeyData,
        currentKeyPairAccountId: String,
        currentSigners: [Horizon.SignerResource],
        defaultRoleId: Uint64,
        defaultWeight: Uint32 = 1000,
        defaultIdentity: Uint32 = 0,
        defaultDetails: Longstring = "{}"
    ) -> [OperationBody] {

        var accountIdData: Uint256 = Uint256()
        accountIdData.wrapped = newKeyPair.getPublicKeyData()
        let newKeyPairAccountId: TokenDWallet.AccountID = TokenDWallet.AccountID.keyTypeEd25519(accountIdData)
        let oldKeyPairAccountId = currentKeyPairAccountId

        var operations: [OperationBody] = []

        for currSigner in currentSigners where currSigner.id == oldKeyPairAccountId {
            guard let role = currSigner.role,
                let roleStringId = role.id,
                let roleId = Uint64(roleStringId),
                roleId != 1 else {
                    continue
            }

            var details = defaultDetails

            if let detailsData = try? JSONSerialization.data(
                withJSONObject: currSigner.details,
                options: .prettyPrinted
                ),
                let encodedDetails = String(data: detailsData, encoding: .utf8) {

                details = encodedDetails
            }

            operations.append(addSigner(
                with: newKeyPairAccountId,
                roleId: roleId,
                weight: currSigner.weight,
                identity: currSigner.identity,
                details: details
                )
            )
        }

        if operations.isEmpty {
            operations.append(addSigner(
                with: newKeyPairAccountId,
                roleId: defaultRoleId,
                weight: defaultWeight,
                identity: defaultIdentity,
                details: defaultDetails
                )
            )
        }

        return operations
    }

    func addSigner(
        with publicKey: PublicKey,
        roleId: Uint64,
        weight: Uint32,
        identity: Uint32,
        details: Longstring
    ) -> OperationBody {

        let updateSignerData: UpdateSignerData = .init(
            publicKey: publicKey,
            roleID: roleId,
            weight: weight,
            identity: identity,
            details: details,
            ext: .emptyVersion
        )
        let data: ManageSignerOp.ManageSignerOpData = .create(updateSignerData)

        let manageSignerOp: ManageSignerOp = .init(
            data: data,
            ext: .emptyVersion
        )

        return .manageSigner(manageSignerOp)
    }

    func removeAllOldSigners(
        from signers: [Horizon.SignerResource],
        currentKeyPairAccountId: String,
        newKeyPairAccountId: String
    ) -> [OperationBody] {

        var operations: [OperationBody] = []

        var signers = signers
        if let index = signers.firstIndex(where: { (signer) -> Bool in
            signer.id == currentKeyPairAccountId
        }) {
            signers.append(signers.remove(at: index))
        }

        for signer in signers where signer.id != newKeyPairAccountId {

            guard let signerId = signer.id,
                let accountIdDecoded = try? Base32Check.decodeCheck(
                    expectedVersion: .accountIdEd25519,
                    encoded: signerId
                ) else {
                    continue
            }

            var accountIdData: Uint256 = Uint256()
            accountIdData.wrapped = accountIdDecoded
            let signerAccountId: TokenDWallet.AccountID = TokenDWallet.AccountID.keyTypeEd25519(accountIdData)

            guard let role = signer.role,
                let roleStringId = role.id,
                roleStringId != "1" else {
                    continue
            }

            operations.append(removeSigner(with: signerAccountId))
        }

        return operations
    }

    func removeSigner(
        with publicKey: PublicKey
    ) -> OperationBody {

        let removeSignerData: RemoveSignerData = .init(
            publicKey: publicKey,
            ext: .emptyVersion
        )
        let data: ManageSignerOp.ManageSignerOpData = .remove(removeSignerData)

        let manageSignerOp: ManageSignerOp = .init(
            data: data,
            ext: .emptyVersion
        )

        return .manageSigner(manageSignerOp)
    }
}

// MARK: - PasswordChangerProtocol

extension BasePasswordChanger: PasswordChangerProtocol {

    func changePassword(
        oldPassword: String,
        newPassword: String,
        completion: @escaping (ChangePasswordResult) -> Void
    ) {

        requestWalletKDF(
            newPassword: newPassword,
            oldPassword: oldPassword,
            completion: completion
        )
    }
}
