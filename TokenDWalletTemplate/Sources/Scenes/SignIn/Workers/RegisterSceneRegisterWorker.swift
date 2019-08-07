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
        
        private let onSubmitEmail: (_ email: String) -> Void
        
        // MARK: -
        
        init(
            appController: AppControllerProtocol,
            flowControllerStack: FlowControllerStack,
            userDataManager: UserDataManagerProtocol,
            keychainManager: KeychainManagerProtocol,
            onSubmitEmail: @escaping (_ email: String) -> Void
            ) {
            
            self.appController = appController
            self.flowControllerStack = flowControllerStack
            self.userDataManager = userDataManager
            self.keychainManager = keychainManager
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
                amountPrecision: self.flowControllerStack.apiConfigurationModel.amountPrecision
            )
            
            self.appController.updateFlowControllerStack(newConfiguration)
            
            return .success
        }
        
        func performSignInRequest(
            email: String,
            password: String,
            completion: @escaping (RegisterSceneSignInResult) -> Void
            ) {
            
            self.onSubmitEmail(email)
            
            self.flowControllerStack.keyServerApi.loginWith(
                email: email,
                password: password,
                completion: { [weak self] (result) in
                    switch result {
                        
                    case .success(let walletDataModel, let keyPair):
                        guard
                            let strongSelf = self,
                            let walletData = WalletDataSerializable.fromWalletData(walletDataModel)
                            else {
                                completion(.failed(.failedToSaveAccount))
                                return
                        }
                        
                        strongSelf.onSuccessfulSignInRequest(
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
        
        // MARK: - SignUpWorker
        
        func performSignUpRequest(
            email: String,
            password: String,
            completion: @escaping (RegisterSceneSignUpResult) -> Void
            ) {
            
            self.onSubmitEmail(email)
            
            self.flowControllerStack.keyServerApi.createWallet(
                email: email,
                password: password,
                referrerAccountId: nil,
                completion: { [weak self] (result) in
                    switch result {
                        
                    case .success(_, let walletDataModel, _, let recoveryKey):
                        guard
                            let strongSelf = self,
                            let walletData = WalletDataSerializable.fromWalletData(walletDataModel)
                            else {
                                completion(.failed(.failedToSaveAccount))
                                return
                        }
                        
                        guard
                            strongSelf.userDataManager.saveWalletData(walletData, account: walletData.email)
                            else {
                                completion(.failed(.failedToSaveAccount))
                                return
                        }
                        
                        let recoverySeed = Base32Check.encode(version: .seedEd25519, data: recoveryKey.getSeedData())
                        
                        completion(.succeeded(
                            account: walletData.email,
                            walletData: walletData,
                            recoverySeed: recoverySeed
                            )
                        )
                        
                    case .failure(let error):
                        let signError: RegisterSceneSignUpResult.SignError
                        
                        switch error {
                            
                        case .emailAlreadyTaken:
                            signError = .emailAlreadyTaken
                            
                        default:
                            signError = .otherError(error)
                        }
                        
                        completion(.failed(signError))
                    }
            })
        }
        
        // MARK: - SignOutWorker
        
        func performSignOut(completion: @escaping () -> Void) {
            
        }
        
        // MARK: - Private
        
        private func onSuccessfulSignInRequest(
            walletData: WalletDataSerializable,
            keyPair: ECDSA.KeyData,
            completion: @escaping (RegisterSceneSignInResult) -> Void
            ) {
            
            let keyDataProvider = UnsafeRequestSignKeyDataProvider(keyPair: keyPair)
            let requestSigner = RequestSigner(keyDataProvider: keyDataProvider)
            
            let usersApi = TokenDSDK.UsersApi(
                apiConfiguration: self.flowControllerStack.keyServerApi.apiConfiguration,
                requestSigner: requestSigner
            )
            
            let accountId = walletData.accountId
            
            usersApi.getUser(accountId: accountId, completion: { [weak self] result in
                switch result {
                    
                case .failure(let errors):
                    if errors.contains(status: ApiError.Status.notFound) {
                        usersApi.createUser(accountId: accountId, completion: { [weak self] createResult in
                            switch createResult {
                                
                            case .failure(let error):
                                completion(.failed(.otherError(error)))
                                
                            case .success:
                                self?.onSuccessfulUserCheck(
                                    walletData: walletData,
                                    keyPair: keyPair,
                                    completion: completion
                                )
                            }
                        })
                    } else {
                        completion(.failed(.otherError(errors)))
                    }
                    
                case .success:
                    self?.onSuccessfulUserCheck(
                        walletData: walletData,
                        keyPair: keyPair,
                        completion: completion
                    )
                }
            })
        }
        
        private func onSuccessfulUserCheck(
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
