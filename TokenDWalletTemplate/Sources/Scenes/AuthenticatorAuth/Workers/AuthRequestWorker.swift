import Foundation
import DLCryptoKit
import TokenDSDK
import TokenDWallet

enum PollAuthResult {
    case failure(String)
    case success(account: String)
}
protocol AuthRequestWorkerProtocol {
    func pollAuthResult(
        key: ECDSA.KeyData,
        completion: @escaping (PollAuthResult) -> Void
    )
    func handleUrl(url: URL, components: URLComponents) -> Bool
}

extension AuthenticatorAuth {
    
    class AuthRequestWorker {
        
        // MARK: - Private properties
        
        private let accountApi: TokenDSDK.AccountsApi
        private let keyServerApi: TokenDSDK.KeyServerApi
        private let generalApi: TokenDSDK.GeneralApi
        private let apiConfigurationModel: APIConfigurationModel
        private let keychainManager: KeychainManagerProtocol
        private let userDataManager: UserDataManagerProtocol
        
        private var isSuccess: Bool?
        private var errorMessage: String?
        
        // MARK: -
        
        init(
            accountApi: TokenDSDK.AccountsApi,
            keyServerApi: TokenDSDK.KeyServerApi,
            generalApi: TokenDSDK.GeneralApi,
            apiConfigurationModel: APIConfigurationModel,
            keychainManager: KeychainManagerProtocol,
            userDataManager: UserDataManagerProtocol
            ) {
            
            self.accountApi = accountApi
            self.keyServerApi = keyServerApi
            self.generalApi = generalApi
            self.apiConfigurationModel = apiConfigurationModel
            self.keychainManager = keychainManager
            self.userDataManager = userDataManager
        }
        
        private func getPublicKey(key: ECDSA.KeyData) -> String {
            return Base32Check.encode(version: .accountIdEd25519, data: key.getPublicKeyData())
        }
        
        private func fetchQueryParameter(parameter: String, queryParams: [URLQueryItem]) -> String? {
            for param in queryParams where param.name == parameter {
                return param.value
            }
            return nil
        }
        
        private func requestDefaultKdf(
            key: ECDSA.KeyData,
            walletId: String,
            completion: @escaping (PollAuthResult) -> Void
            ) {
            
            self.keyServerApi.requestDefaultKDF { [weak self] (result) in
                switch result {
                    
                case .failure(let error):
                    completion(.failure(error.localizedDescription))
                    
                case .success(let kdfParams):
                    self?.requestWalletData(
                        key: key,
                        walletId: walletId,
                        kdfParams: kdfParams,
                        completion: completion
                    )
                }
            }
        }
        
        private func requestWalletData(
            key: ECDSA.KeyData,
            walletId: String,
            kdfParams: KDFParams,
            completion: @escaping (PollAuthResult) -> Void
            ) {
            guard let salt = Date().description.data(using: .utf8) else {
                completion(.failure(Localized(.failed_to_build_kdf_params)))
                return
            }
            
            let walletKdfParams = WalletKDFParams(kdfParams: kdfParams, salt: salt)
            self.keyServerApi.requestWallet(
                walletId: walletId,
                walletKDF: walletKdfParams,
                completion: { [weak self] (result) in
                    switch result {
                        
                    case .failure(let error):
                        completion(.failure(error.localizedDescription))
                        
                    case .success(let walletDataModel):
                        self?.requestNetworkInfo(
                            key: key,
                            walletDataModel: walletDataModel,
                            completion: completion
                        )
                    }
            })
        }
        
        private func requestNetworkInfo(
            key: ECDSA.KeyData,
            walletDataModel: WalletDataModel,
            completion: @escaping (PollAuthResult) -> Void
            ) {
            
            self.generalApi.requestNetworkInfo { [weak self] (result) in
                switch result {
                    
                case .failed(let error):
                    completion(.failure(error.localizedDescription))
                    
                case .succeeded(let network):
                    self?.saveWallet(
                        key: key,
                        walletDataModel: walletDataModel,
                        network: network,
                        completion: completion
                    )
                }
            }
        }
        
        private func saveWallet(
            key: ECDSA.KeyData,
            walletDataModel: WalletDataModel,
            network: NetworkInfoModel,
            completion: @escaping (PollAuthResult) -> Void
            ) {
            
            let accountNetwork = WalletDataSerializable.AccountNetworkModel(
                masterAccountId: network.masterAccountId,
                name: network.masterExchangeName,
                passphrase: network.networkParams.passphrase,
                rootUrl: self.apiConfigurationModel.apiEndpoint,
                storageUrl: self.apiConfigurationModel.storageEndpoint
            )
            guard let walletData = WalletDataSerializable.fromWalletData(
                walletDataModel,
                signedViaAuthenticator: true,
                network: accountNetwork
                ) else {
                    completion(.failure(Localized(.failed_to_get_wallet_data)))
                    return
            }
            
            if self.keychainManager.saveAccount(walletDataModel.email),
                self.keychainManager.saveKeyData(key, account: walletDataModel.email),
                self.userDataManager.saveWalletData(walletData, account: walletDataModel.email) {
                
                completion(.success(account: walletDataModel.email))
            } else {
                completion(.failure(Localized(.failed_to_save_key_and_wallet_data)))
            }
        }
    }
}

extension AuthenticatorAuth.AuthRequestWorker: AuthRequestWorkerProtocol {
    
    func pollAuthResult(
        key: ECDSA.KeyData,
        completion: @escaping (PollAuthResult) -> Void
        ) {
        
        let publicKey = self.getPublicKey(key: key)
        self.accountApi.requestAuthResult(
            accountId: publicKey,
            completion: { [weak self] (result) in
                
                switch result {
                    
                case .failure:
                    guard let isSuccess = self?.isSuccess,
                        let errorMessage = self?.errorMessage else {
                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + 1.5,
                                execute: { [weak self] in
                                    self?.pollAuthResult(key: key, completion: completion)
                            })
                            return
                    }
                    
                    if !isSuccess {
                        completion(.failure(errorMessage))
                    }
                    
                case .success(let response):
                    self?.requestDefaultKdf(
                        key: key,
                        walletId: response.walletId,
                        completion: completion
                    )
                }
        })
    }
    
    func handleUrl(url: URL, components: URLComponents) -> Bool {
        guard let queryItems = components.queryItems else {
            self.errorMessage = Localized(.query_parameters_are_missing)
            self.isSuccess = false
            return false
        }
        
        guard let literalResult = self.fetchQueryParameter(parameter: Localized(.success), queryParams: queryItems),
            let isSuccess = Bool(literalResult) else {
                self.errorMessage = Localized(.success_parameter_is_missing_or_invalid)
                self.isSuccess = false
                return false
        }
        
        if isSuccess {
            self.isSuccess = true
        } else {
            let error = self.fetchQueryParameter(
                parameter: Localized(.error),
                queryParams: queryItems
                ) ?? Localized(.unknown_error)
            self.errorMessage = error
            self.isSuccess = false
        }
        return true
    }
}
