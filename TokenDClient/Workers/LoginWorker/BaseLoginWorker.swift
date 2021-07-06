import Foundation
import TokenDSDK
import TokenDWallet
import DLCryptoKit

class BaseLoginWorker {

    enum SaveWalletError: Swift.Error {
        case failedToSaveWallet
    }

    private let walletDataProvider: WalletDataProviderProtocol
    private let userDataManager: UserDataManagerProtocol
    private let keychainManager: KeychainManagerProtocol

    init(
        walletDataProvider: WalletDataProviderProtocol,
        userDataManager: UserDataManagerProtocol,
        keychainManager: KeychainManagerProtocol
    ) {

        self.walletDataProvider = walletDataProvider
        self.userDataManager = userDataManager
        self.keychainManager = keychainManager
    }
}

// MARK: - Private methods

private extension BaseLoginWorker {

    func fetchWalletData(
        login: String,
        password: String,
        completion: @escaping (LoginWorkerResult) -> Void
    ) {

        walletDataProvider.walletData(
            for: login,
            password: password,
            completion: { [weak self] (result) in

                switch result {

                case .failure(let error):
                    completion(.failure(error))

                case .success(let walletDataModel, let keyPairs):

                    self?.saveWalletAndFinish(
                        walletData: walletDataModel,
                        keyPairs: keyPairs,
                        completion: completion
                    )
                }
            })
    }
    
    func saveWalletAndFinish(
        walletData: WalletDataSerializable,
        keyPairs: [ECDSA.KeyData],
        completion: @escaping (LoginWorkerResult) -> Void
    ) {

        guard
            keychainManager.saveKeyData(keyPairs, account: walletData.email),
            userDataManager.saveWalletData(walletData, account: walletData.email)
            else {
                completion(.failure(SaveWalletError.failedToSaveWallet))
                return
        }

        completion(.success(login: walletData.email))
    }
}

extension BaseLoginWorker: LoginWorkerProtocol {

    func loginAction(
        login: String,
        password: String,
        completion: @escaping (LoginWorkerResult) -> Void) {

        fetchWalletData(
            login: login,
            password: password,
            completion: completion
        )
    }
}
