import Foundation
import TokenDSDK
import TokenDWallet
import DLCryptoKit

class BaseRegisterWorker {

    private let keyServerApi: KeyServerApi
    private let keysProvider: KeyServerAPIKeysProviderProtocol

    init(
        keyServerApi: KeyServerApi,
        keysProvider: KeyServerAPIKeysProviderProtocol
    ) {

        self.keyServerApi = keyServerApi
        self.keysProvider = keysProvider
    }
}

// MARK: - Private methods

private extension BaseRegisterWorker {
    
    func requestDefaultKDF(
        login: String,
        password: String,
        completion: @escaping (RegisterWorkerResult) -> Void
    ) {

        keyServerApi
            .getDefaultKDFParams(
                completion: { [weak self] (result) in
                    switch result {

                    case .failure(let error):
                        completion(.failure(error))

                    case .success(let kdfParams):
                        self?.getSigners(
                            login: login,
                            password: password,
                            kdfParams: kdfParams,
                            completion: completion
                        )
                    }
                }
            )
    }
    
    func getSigners(
        login: String,
        password: String,
        kdfParams: KDFParams,
        completion: @escaping (RegisterWorkerResult) -> Void
    ) {
    
        keysProvider.getSigners { [weak self] (result) in
            
            switch result {
            
            case .failure(let error):
                completion(.failure(error))
                
            case .success(let signers):
                self?.createWalletInfo(
                    login: login,
                    password: password,
                    kdfParams: kdfParams,
                    signers: signers,
                    completion: completion
                )
            }
        }
    }

    func createWalletInfo(
        login: String,
        password: String,
        kdfParams: KDFParams,
        signers: [WalletInfoModelV2.WalletInfoData.Relationships.Signer],
        completion: @escaping (RegisterWorkerResult) -> Void
        ) {

        let createRegistrationInfoResult = WalletInfoBuilderV2.createWalletInfo(
            login: login,
            password: password,
            kdfParams: kdfParams,
            keys: keysProvider.keys,
            signers: signers,
            transaction: nil
        )

        switch createRegistrationInfoResult {

        case .failure(let error):
            completion(.failure(error))

        case .success(let walletInfo):
            createWallet(
                login: login,
                walletInfo: walletInfo,
                completion: completion
            )
        }
    }

    func createWallet(
        login: String,
        walletInfo: WalletInfoModelV2,
        completion: @escaping (RegisterWorkerResult) -> Void
    ) {

        keyServerApi
            .createWalletV2(
                walletInfo: walletInfo,
                completion: { (result) in

                    switch result {

                    case .failure(let error):
                        completion(.failure(error))

                    case .success:
                        completion(.success(login: login))
                    }
                })
    }
}

extension BaseRegisterWorker: RegisterWorkerProtocol {

    func registerAction(
        login: String,
        password: String,
        completion: @escaping (RegisterWorkerResult) -> Void
    ) {

        requestDefaultKDF(
            login: login,
            password: password,
            completion: completion
        )
    }
}
