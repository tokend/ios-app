import Foundation
import TokenDSDK
import TokenDWallet

extension RegisterScene {
    class LocalSignInWorker: RegisterWorker {
        
        // MARK: - Private properties
        
        private let userDataManager: UserDataManagerProtocol
        private let keychainManager: KeychainManagerProtocol
        
        // MARK: -
        
        init(
            userDataManager: UserDataManagerProtocol,
            keychainManager: KeychainManagerProtocol
            ) {
            
            self.userDataManager = userDataManager
            self.keychainManager = keychainManager
        }
        
        // MARK: - SignInWorker
        
        func performSignInRequest(
            email: String,
            password: String,
            completion: @escaping (RegisterSceneSignInResult) -> Void
            ) {
            
            guard let walletData = self.userDataManager.getWalletData(account: email) else {
                completion(.failed(.wrongPassword))
                return
            }
            
            let walletKDF = walletData.walletKDF.getWalletKDFParams()
            
            let checkedEmail = walletKDF.kdfParams.checkedLogin(email)
            
            do {
                guard let derivedKey = try KeyPairBuilder.getKeyPairs(
                    forLogin: checkedEmail,
                    password: password,
                    keychainData: walletData.keychainData,
                    walletKDF: walletKDF
                ).first else {
                    completion(.failed(.wrongPassword))
                    return
                }
                
                if self.keychainManager.validateDerivedKeyData(derivedKey, account: email) {
                    completion(.succeeded(account: email))
                } else {
                    completion(.failed(.wrongPassword))
                }
            } catch {
                completion(.failed(.wrongPassword))
            }
        }
        
        // MARK: - SignUpWorker
        
        func performSignUpRequest(
            email: String,
            password: String,
            completion: @escaping (RegisterSceneSignUpResult) -> Void
            ) {
            
            completion(.failed(.failedToSaveAccount))
        }
        
        // MARK: - SignOutWorker
        
        func performSignOut(completion: @escaping () -> Void) {
            self.userDataManager.clearAllData()
            self.keychainManager.clearAllData()
            
            completion()
        }
        
        func getServerInfoTitle() -> String {
            return ""
        }
        
        func handleServerInfoQRScannedString(_ value: String) -> RegisterSceneSignInWorkerProtocol.QRCodeParseResult {
            return .failure
        }
    }
}
