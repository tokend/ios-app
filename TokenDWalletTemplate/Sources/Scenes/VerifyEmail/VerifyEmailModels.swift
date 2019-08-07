import Foundation

enum VerifyEmail {
    
    // MARK: - Typealiases
    
    // MARK: -
    
    enum Model {}
    enum Event {}
}

// MARK: - Models

extension VerifyEmail.Model {
    
}

// MARK: - Events

extension VerifyEmail.Event {
    enum ViewDidLoad {
        struct Request {}
    }
    
    enum ResendEmail {
        struct Request {}
        
        enum Response {
            case failed(Error)
            case loaded
            case loading
        }
        
        enum ViewModel {
            case failed(errorMessage: String)
            case loaded
            case loading
        }
    }
    
    enum VerifyToken {
        enum Response {
            case failed(Error)
            case loaded
            case loading
            case succeded
        }
        
        enum ViewModel {
            case failed(errorMessage: String)
            case loaded
            case loading
            case succeded
        }
    }
}
