import Foundation
import TokenDSDK
import TokenDWallet
import DLCryptoKit

extension RegisterScene {
    class TokenDRegisterWorker: RegisterWorker {
        
        // MARK: - Private properties
        
        private let appController: AppControllerProtocol
        private let flowControllerStack: FlowControllerStack
        private let userDataManager: UserDataManagerProtocol
        private let keychainManager: KeychainManagerProtocol
        private let signUpRequestBuilder: RegisterSceneSignUpBuilderProtocol
        
        private let onSubmitEmail: (_ email: String) -> Void
        
        // MARK: -
        
        init(
            appController: AppControllerProtocol,
            flowControllerStack: FlowControllerStack,
            userDataManager: UserDataManagerProtocol,
            keychainManager: KeychainManagerProtocol,
            signUpRequestBuilder: RegisterSceneSignUpBuilderProtocol,
            onSubmitEmail: @escaping (_ email: String) -> Void
            ) {
            
            self.appController = appController
            self.flowControllerStack = flowControllerStack
            self.userDataManager = userDataManager
            self.keychainManager = keychainManager
            self.signUpRequestBuilder = signUpRequestBuilder
            self.onSubmitEmail = onSubmitEmail
        }
        
        // MARK: - SignInWorker
        
        func getServerInfoTitle() -> String {
            var title = self.flowControllerStack.apiConfigurationModel.apiEndpoint
            
            let prefixes = [
                "https:",
                "http:"
            ]
            
            for prefix in prefixes {
                if title.hasPrefix(prefix) {
                    let prefixLength = prefix.count
                    let startIndex = title.index(title.startIndex, offsetBy: prefixLength)
                    let endIndex = title.endIndex
                    
                    title = String(title[Range<String.Index>(uncheckedBounds: (startIndex, endIndex))])
                    
                    break
                }
            }
            
            title = title.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            
            return title
        }
        
        func handleServerInfoQRScannedString(_ value: String) -> QRCodeParseResult {
            let data = Data(value.utf8)
            
            guard let serverInfo = try? JSONDecoder().decode(Model.ServerInfoParsed.self, from: data) else {
                return .failure
            }
            
            let newConfiguration = APIConfigurationModel(
                storageEndpoint: serverInfo.storage,
                apiEndpoint: serverInfo.api,
                termsAddress: serverInfo.terms,
                webClient: serverInfo.web,
                downloadUrl: serverInfo.download
            )
            
            self.appController.updateFlowControllerStack(newConfiguration, self.keychainManager)
            
            return .success
        }
        
        func performSignInRequest(
            email: String,
            password: String,
            completion: @escaping (RegisterSceneSignInResult) -> Void
            ) {
            
            self.onSubmitEmail(email)
            
            self.flowControllerStack.api.generalApi.requestNetworkInfo { [weak self] (result) in
                switch result {
                    
                case .failed(let error):
                    
                    switch error {
                        
                    case .failedToDecode,
                         .requestError:
                        completion(.failed(.failedToSaveNetwork))
                        
                    case .transportSecurity:
                        completion(.failed(.otherError(error)))
                    }
                    
                case .succeeded(let network):
                    self?.signIn(
                        email: email,
                        password: password,
                        network: network,
                        completion: completion
                    )
                }
            }
        }
        
        // MARK: - SignUpWorker
        
        func performSignUpRequest(
            email: String,
            password: String,
            completion: @escaping (RegisterSceneSignUpResult) -> Void
            ) {
            
            self.onSubmitEmail(email)
            
            self.flowControllerStack.api.generalApi.requestNetworkInfo { [weak self] (result) in
                switch result {
                    
                case .failed(let error):
                    switch error {
                        
                    case .failedToDecode,
                         .requestError:
                        completion(.failed(.failedToSaveNetwork))
                        
                    case .transportSecurity:
                        completion(.failed(.otherError(error)))
                    }
                    
                case .succeeded(let network):
                    self?.buildSignUpRequest(
                        email: email,
                        password: password,
                        network: network,
                        completion: completion
                    )
                }
            }
        }
        
        // MARK: - SignOutWorker
        
        func performSignOut(completion: @escaping () -> Void) {
            
        }
        
        // MARK: - Private
        
        private func signIn(
            email: String,
            password: String,
            network: NetworkInfoModel,
            completion: @escaping (RegisterSceneSignInResult) -> Void
            ) {
            
            self.flowControllerStack.keyServerApi.loginWith(
                email: email,
                password: password,
                completion: { [weak self] (result) in
                    switch result {
                        
                    case .success(let walletDataModel, let keyPair):
                        guard let strongSelf = self else {
                            completion(.failed(.failedToSaveAccount))
                            return
                        }
                        
                        let network = WalletDataSerializable.AccountNetworkModel(
                            masterAccountId: network.masterAccountId,
                            name: network.masterExchangeName,
                            passphrase: network.networkParams.passphrase,
                            rootUrl: strongSelf.flowControllerStack.apiConfigurationModel.apiEndpoint,
                            storageUrl: strongSelf.flowControllerStack.apiConfigurationModel.storageEndpoint
                        )
                        guard let walletData = WalletDataSerializable.fromWalletData(
                            walletDataModel,
                            signedViaAuthenticator: false,
                            network: network
                            ) else {
                                completion(.failed(.failedToSaveAccount))
                                return
                        }
                        
                        self?.onSuccessfulSignInRequest(
                            walletData: walletData,
                            keyPair: keyPair,
                            completion: completion
                        )
                        
                    case .failure(let error):
                        let signError: RegisterSceneSignInResult.SignError
                        
                        switch error {
                            
                        case .requestWalletError(let requestWalletError):
                            switch requestWalletError {
                                
                            case .wrongEmail:
                                signError = .wrongEmail
                                
                            case .wrongPassword:
                                signError = .wrongPassword
                                
                            case .emailShouldBeVerified(let walletId):
                                signError = .emailShouldBeVerified(walletId: walletId)
                                
                            case .tfaFailed:
                                signError = .tfaFailed
                                
                            default:
                                signError = .otherError(requestWalletError)
                            }
                            
                        case .walletKDFError(let walletKDFError):
                            switch walletKDFError {
                                
                            case .emailNotFound:
                                signError = .wrongPassword
                                
                            default:
                                signError = .otherError(walletKDFError)
                            }
                            
                        default:
                            signError = .otherError(error)
                        }
                        
                        completion(.failed(signError))
                    }
            })
        }
        
        private func buildSignUpRequest(
            email: String,
            password: String,
            network: NetworkInfoModel,
            completion: @escaping (RegisterSceneSignUpResult) -> Void
            ) {
            
            let accountNetwork = WalletDataSerializable.AccountNetworkModel(
                masterAccountId: network.masterAccountId,
                name: network.masterExchangeName,
                passphrase: network.networkParams.passphrase,
                rootUrl: self.flowControllerStack.apiConfigurationModel.apiEndpoint,
                storageUrl: self.flowControllerStack.apiConfigurationModel.storageEndpoint
            )
            
            self.signUpRequestBuilder.buildSignUpRequest(
                for: email,
                password: password,
                completion: { [weak self] (result) in
                    switch result {
                        
                    case .failure(let error):
                        completion(.failed(.otherError(error)))
                        
                    case .success(let email, let recoveryKey, let walletInfo, let walletKDF):
                        self?.showRecovery(
                            email: email,
                            recoveryKey: recoveryKey,
                            walletInfo: walletInfo,
                            walletKDF: walletKDF,
                            accountNetwork: accountNetwork,
                            completion: completion
                        )
                    }
            })
        }
        
        private func showRecovery(
            email: String,
            recoveryKey: ECDSA.KeyData,
            walletInfo: WalletInfoModel,
            walletKDF: WalletKDFParams,
            accountNetwork: WalletDataSerializable.AccountNetworkModel,
            completion: @escaping (RegisterSceneSignUpResult) -> Void
            ) {
            
            let recoverySeed = Base32Check.encode(version: .seedEd25519, data: recoveryKey.getSeedData())
            
            let model = SignUpModel(
                email: email,
                recoverySeed: recoverySeed,
                walletInfo: walletInfo,
                walletKDF: walletKDF,
                accountNetwork: accountNetwork
            )
            completion(.succeeded(model: model))
        }
        
        private func onSuccessfulSignInRequest(
            walletData: WalletDataSerializable,
            keyPair: ECDSA.KeyData,
            completion: @escaping (RegisterSceneSignInResult) -> Void
            ) {
            
            guard
                self.keychainManager.saveKeyData(keyPair, account: walletData.email),
                self.userDataManager.saveWalletData(walletData, account: walletData.email)
                else {
                    completion(.failed(.failedToSaveAccount))
                    return
            }
            
            completion(.succeeded(account: walletData.email))
        }
    }
}

extension RegisterScene.TokenDRegisterWorker {
    
    struct SignUpModel {
        let email: String
        let recoverySeed: String
        let walletInfo: WalletInfoModel
        let walletKDF: WalletKDFParams
        let accountNetwork: WalletDataSerializable.AccountNetworkModel
    }
}
