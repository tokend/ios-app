import UIKit
import LocalAuthentication

extension BiometricsAuth {
    
    class BiometricsAuthWorker: AuthWorkerProtocol {
        
        // MARK: - Public properties
        
        let keychainManager: KeychainManagerProtocol
        
        // MARK: -
        
        init(
            keychainManager: KeychainManagerProtocol
            ) {
            
            self.keychainManager = keychainManager
        }
        
        // MARK: - AuthWorker
        
        func performAuth(
            completion: @escaping ((_ result: BiometricsAuthWorkerResult) -> Void)
            ) {
            
            let context = LAContext()
            var error: NSError?
            
            guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
                completion(.failure)
                
                return
            }
            
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: Localized(.signing_in)
            ) { [weak self] (success, error) in
                
                DispatchQueue.main.async {
                    if success, let account = self?.keychainManager.getMainAccount() {
                        completion(.success(login: account))
                    } else if let nsError = error as NSError? {
                        let laError = LAError(_nsError: nsError)
                        
                        switch laError.code {
                            
                        case .authenticationFailed:
                            completion(.failure)
                            
                        case .userCancel:
                            completion(.userCancel)
                        
                        case .userFallback:
                            completion(.userFallback)
                            
                        case .systemCancel:
                            break
                            
                        default:
                            completion(.failure)
                        }
                    } else {
                        completion(.failure)
                    }
                }
            }
        }
    }
}
