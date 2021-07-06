import Foundation
import TokenDSDK
import TokenDWallet

class RecoveryStatusChecker {

    // MARK: - Private properties

    private let accountsApi: AccountsApiV3
    private let keyServerApi: KeyServerApi
    private let transactionCreator: TransactionCreator
    private let transactionSender: TransactionSender
    private let userDataProvider: UserDataProviderProtocol
    private let keychainDataProvider: KeychainDataProviderProtocol

    // MARK: -

    init(
        accountsApi: AccountsApiV3,
        keyServerApi: KeyServerApi,
        transactionCreator: TransactionCreator,
        transactionSender: TransactionSender,
        userDataProvider: UserDataProviderProtocol,
        keychainDataProvider: KeychainDataProviderProtocol
        ) {

        self.accountsApi = accountsApi
        self.keyServerApi = keyServerApi
        self.transactionCreator = transactionCreator
        self.transactionSender = transactionSender
        self.userDataProvider = userDataProvider
        self.keychainDataProvider = keychainDataProvider
    }
}

// MARK: - Private methods

private extension RecoveryStatusChecker {

    private enum KYCRecoveryStatus: Int32 {
        case none                   = 0
        case initiated              = 1
        case pending                = 2
        case rejected               = 3
        case permanentlyRejected    = 4
    }

    enum CheckKYCRecoveryStatusError: Swift.Error {

        case notEnoughData
    }
    func checkKYCRecoveryStatus(
        _ completion: @escaping (RecoveryStatusCheckerResult) -> Void
    ) {

        accountsApi.requestAccount(
            accountId: userDataProvider.walletData.accountId,
            include: nil,
            pagination: nil,
            completion: { [weak self] (result) in

                switch result {

                case .failure(let error):
                    completion(.failure(error))

                case .success(let document):
                    guard let status = document.data?.kycRecoveryStatus?.value,
                        let kycRecoveryStatus = KYCRecoveryStatus(rawValue: status)
                        else {
                            completion(.failure(CheckKYCRecoveryStatusError.notEnoughData))
                            return
                    }

                    switch kycRecoveryStatus {

                    case .none,
                         .pending,
                         .permanentlyRejected,
                         .rejected:
                        completion(.success)

                    case .initiated:
                        self?.requestDefaultSignerRoleId(completion)
                    }
                }
        })
    }

    func requestDefaultSignerRoleId(
        _ completion: @escaping (RecoveryStatusCheckerResult) -> Void
    ) {

        keyServerApi.getDefaultSignerRoleId(completion: { [weak self] (result) in

            switch result {

            case .failure(let errors):
                completion(.failure(errors))

            case .success(let response):

                let defaultRoleId: Uint64 = .init(response.roleId)
                self?.createKYCRecovery(
                    defaultRoleId: defaultRoleId,
                    completion
                )
            }
        })
    }

    func createKYCRecovery(
        defaultRoleId: Uint64,
        _ completion: @escaping (RecoveryStatusCheckerResult) -> Void
    ) {

        let keyData = keychainDataProvider.getKeyData()

        var accountIdData: Uint256 = Uint256()
        accountIdData.wrapped = keyData.getPublicKeyData()
        let keyPairAccountId: TokenDWallet.AccountID = TokenDWallet.AccountID.keyTypeEd25519(accountIdData)
        let signer = UpdateSignerData(
            publicKey: keyPairAccountId,
            roleID: defaultRoleId,
            weight: 1000,
            identity: 0,
            details: "{}",
            ext: .emptyVersion
        )

        let op: CreateKYCRecoveryRequestOp = .init(
            requestID: 0,
            targetAccount: userDataProvider.accountId,
            signersData: [signer],
            creatorDetails: "{}",
            allTasks: nil,
            ext: .emptyVersion
        )

        transactionCreator.createTransaction(
            sourceAccountId: userDataProvider.accountId,
            operations: [
                .createKycRecoveryRequest(op)
            ],
            sendDate: Date(),
            completion: { [weak self] (result) in

                switch result {

                case .failure(let error):
                    completion(.failure(error))

                case .success(let transaction):
                    self?.transactionSender.sendTransactionV3(
                        transaction,
                        completion: { (result) in

                            switch result {

                            case .failed(let error):
                                completion(.failure(error))

                            case .succeeded:
                                completion(.success)
                            }
                    })
                }
        })
    }
}

// MARK: - RecoveryStatusCheckerProtocol

extension RecoveryStatusChecker: RecoveryStatusCheckerProtocol {

    func checkRecoveryStatus(
        _ completion: @escaping (RecoveryStatusCheckerResult) -> Void
    ) {

        checkKYCRecoveryStatus(completion)
    }
}
