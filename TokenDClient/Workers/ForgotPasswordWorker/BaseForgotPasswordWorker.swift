import Foundation
import TokenDSDK
import TokenDWallet
import DLCryptoKit

class BaseForgotPasswordWorker {

    // MARK: - Private properties

    private let keyServerApi: KeyServerApi
    private let keychainManager: KeychainManagerProtocol
    private let keysProvider: KeyServerAPIKeysProviderProtocol

    // MARK: -

    init(
        keyServerApi: KeyServerApi,
        keychainManager: KeychainManagerProtocol,
        keysProvider: KeyServerAPIKeysProviderProtocol
    ) {

        self.keyServerApi = keyServerApi
        self.keychainManager = keychainManager
        self.keysProvider = keysProvider
    }
}

// MARK: - Private methods

private extension BaseForgotPasswordWorker {

    typealias OperationBody = TokenDWallet.Operation.OperationBody

    func requestWalletKDF(
        login: String,
        newPassword: String,
        completion: @escaping (Result<Void, Swift.Error>) -> Void
    ) {

        keyServerApi.getWalletKDF(
            login: login,
            isRecovery: true,
            completion: { [weak self] (result) in

                switch result {

                case .success(let walletKDF):

                    self?.createWalletInfo(
                        login: login,
                        newPassword: newPassword,
                        walletKDF: walletKDF,
                        completion: completion
                    )

                case .failure(let error):
                    completion(.failure(error))
                }
        })
    }

    func createWalletInfo(
        login: String,
        newPassword: String,
        walletKDF: WalletKDFParams,
        completion: @escaping (Result<Void, Swift.Error>) -> Void
    ) {

        let result = WalletInfoBuilderV2.createRecoveryWalletInfo(
            login: login,
            password: newPassword,
            kdfParams: walletKDF.kdfParams,
            keys: keysProvider.keys
        )

        switch result {

        case .failure(let error):
            completion(.failure(error))

        case .success(let walletInfo):
            updateWallet(
                login: login,
                newPassword: newPassword,
                walletKDF: walletKDF,
                walletInfo: walletInfo,
                completion: completion
            )
        }
    }

    func updateWallet(
        login: String,
        newPassword: String,
        walletKDF: WalletKDFParams,
        walletInfo: WalletInfoModelV2,
        completion: @escaping (Result<Void, Swift.Error>) -> Void
    ) {

        let onSignRequest = JSONAPI.RequestSignerBlockCaller.getUnsafeSignRequestBlock()
        let requestSigner = JSONAPI.RequestSignerBlockCaller(
            signingKey: keysProvider.requestSigningKey,
            accountId: walletInfo.data.attributes.accountId,
            onSignRequest: onSignRequest
        )

        keyServerApi.putWallet(
            login: login,
            walletId: walletInfo.data.id,
            signingPassword: newPassword,
            walletKDF: walletKDF,
            walletInfo: walletInfo,
            requestSigner: requestSigner,
            completion: { [weak self] (result) in

                switch result {

                case .success:
                    self?.saveKeys(login: login)
                    completion(.success(()))

                case .failure(let error):
                    completion(.failure(error))
                }
        })
    }
    
    func saveKeys(
        login: String
    ) {
        // FIXME: - Save new wallet ID
        _ = keychainManager.saveKeyData(keysProvider.keys, account: login)
    }
}

// MARK: - ForgotPasswordWorkerProtocol

extension BaseForgotPasswordWorker: ForgotPasswordWorkerProtocol {

    func changePassword(
        login: String,
        newPassword: String,
        completion: @escaping (Result<Void, Swift.Error>) -> Void
    ) {

        requestWalletKDF(
            login: login,
            newPassword: newPassword,
            completion: completion
        )
    }
}
