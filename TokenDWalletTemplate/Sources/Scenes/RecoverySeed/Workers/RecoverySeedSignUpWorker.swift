import Foundation
import TokenDSDK

enum RecoverySeedSignUpWorkerResult {
    enum SignUpError: Error, LocalizedError {
        case emailAlreadyTaken
        case failedToSaveAccount
        case other(Swift.Error)
        
        public var errorDesription: String? {
            switch  self {
                
            case .emailAlreadyTaken:
                return Localized(.email_already_taken)
                
            case .failedToSaveAccount:
                return Localized(.failed_to_save_account_data)
                
            case .other(let error):
                return error.localizedDescription
            }
        }
    }
    
    case success(account: String, walletData: RecoverySeed.Model.WalletData)
    case failure(SignUpError)
}
protocol RecoverySeedSignUpWorkerProtocol {
    func signUp(completion: @escaping((RecoverySeedSignUpWorkerResult) -> Void))
}

extension RecoverySeed {
    typealias SignUpWorkerProtocol = RecoverySeedSignUpWorkerProtocol
    typealias SignUpModel = RegisterScene.TokenDRegisterWorker.SignUpModel
    
    class SignUpWorker {
        
        // MARK: - Private properties
        
        private let keyServerApi: KeyServerApi
        private let userDataManager: UserDataManagerProtocol
        private let signUpModel: SignUpModel
        
        init(
            keyServerApi: KeyServerApi,
            userDataManager: UserDataManagerProtocol,
            signUpModel: SignUpModel
            ) {
            
            self.keyServerApi = keyServerApi
            self.userDataManager = userDataManager
            self.signUpModel = signUpModel
        }
    }
}

extension RecoverySeed.SignUpWorker: RecoverySeed.SignUpWorkerProtocol {
    
    func signUp(completion: @escaping ((RecoverySeedSignUpWorkerResult) -> Void)) {
        self.keyServerApi.createWallet(
            walletInfo: self.signUpModel.walletInfo,
            completion: { [weak self] (result) in
                switch result {
                    
                case .failure(let error):
                    let signError: RecoverySeedSignUpWorkerResult.SignUpError
                    
                    switch error {
                        
                    case .emailAlreadyTaken:
                        signError = .emailAlreadyTaken
                        
                    default:
                        signError = .other(error)
                    }
                    
                    completion(.failure(signError))
                    
                case .success(let response):
                    guard let strongSelf = self else {
                        completion(.failure(.failedToSaveAccount))
                        return
                    }
                    let walletDataModel = WalletDataModel(
                        email: strongSelf.signUpModel.email,
                        accountId: strongSelf.signUpModel.walletInfo.data.attributes.accountId,
                        walletId: response.id,
                        type: response.type,
                        keychainData: strongSelf.signUpModel.walletInfo.data.attributes.keychainData,
                        walletKDF: strongSelf.signUpModel.walletKDF,
                        verified: response.attributes.verified
                    )
                    guard
                        let walletData = WalletDataSerializable.fromWalletData(
                            walletDataModel,
                            signedViaAuthenticator: false,
                            network: strongSelf.signUpModel.accountNetwork
                        )
                        else {
                            completion(.failure(.failedToSaveAccount))
                            return
                    }
                    
                    guard
                        strongSelf.userDataManager.saveWalletData(walletData, account: walletData.email)
                        else {
                            completion(.failure(.failedToSaveAccount))
                            return
                    }
                    
                    completion(.success(
                        account: walletData.email,
                        walletData: walletData
                        )
                    )
                }
        })
    }
}
