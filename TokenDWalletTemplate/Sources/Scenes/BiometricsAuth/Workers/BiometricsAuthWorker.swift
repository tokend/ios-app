import UIKit
import LocalAuthentication

enum BiometricsAuthResult {
    case failure
    case success(account: String)
    case userCancel
    case userFallback
}

protocol BiometricsAuthWorkerProtocol {
    typealias Result = BiometricsAuthResult
    
    func performAuth(
        completion: @escaping ((_ result: Result) -> Void)
    )
}

extension BiometricsAuth {
    
    typealias AuthWorker = BiometricsAuthWorkerProtocol
    
    class BiometricsAuthWorker: AuthWorker {
        
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
            completion: @escaping ((_ result: BiometricsAuthResult) -> Void)
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
                        completion(.success(account: account))
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
