import UIKit

enum BiometricsAuth {
    
    // MARK: - Typealiases
    
    // MARK: -
    
    enum Model {}
    enum Event {}
}

// MARK: - Models

extension BiometricsAuth.Model {
    
}

// MARK: - Events

extension BiometricsAuth.Event {
    enum ViewDidAppear {
        struct Request {}
        
        struct Response {
            let result: BiometricsAuth.AuthWorker.Result
        }
        
        enum ViewModel {
            case failure
            case success(account: String)
            case userCancel
            case userFallback
        }
    }
}
