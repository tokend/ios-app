import UIKit

public enum SignUpScene {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension SignUpScene.Model {
    
    struct SceneModel {
        var network: String?
        var email: String?
        var password: String?
        var passwordConfirmation: String?
        var networkError: NetworkValidationError?
        var emailError: EmailValidationError?
        var passwordError: PasswordValidationError?
        var passwordConfirmationError: PasswordConfirmationError?
    }
    
    struct SceneViewModel {
        let network: String?
        let email: String?
        let password: String?
        let passwordConfirmation: String?
        let networkError: String?
        let emailError: String?
        let passwordError: String?
        let passwordConfirmationError: String?
    }
    
    public enum NetworkValidationError {
        case emptyString
    }
    
    public enum EmailValidationError {
        case emailDoesNotMatchRequirements
        case emptyString
    }
    
    public enum PasswordValidationError {
        case passwordDoesNotMatchRequirements
        case emptyString
    }
    
    public enum PasswordConfirmationError {
        case passwordsDoNotMatch
        case emptyString
    }
}

// MARK: - Events

extension SignUpScene.Event {
    
    public typealias Model = SignUpScene.Model
    
    // MARK: -
    
    public enum ViewDidLoad {
        public struct Request {}
    }
    
    public enum ViewDidLoadSync {
        public struct Request {}
    }
    
    public enum SceneDidUpdate {
        public struct Response {
            let sceneModel: Model.SceneModel
            let animated: Bool
        }

        public struct ViewModel {
            let viewModel: Model.SceneViewModel
            let animated: Bool
        }
    }

    public enum SceneDidUpdateSync {
        public struct Response {
            let sceneModel: Model.SceneModel
            let animated: Bool
        }

        public struct ViewModel {
            let viewModel: Model.SceneViewModel
            let animated: Bool
        }
    }
    
    public enum DidEnterEmailSync {
        public struct Request {
            let value: String?
        }
    }
    
    public enum DidEnterPasswordSync {
        public struct Request {
            let value: String?
        }
    }
    
    public enum DidEnterPasswordConfirmationSync {
        public struct Request {
            let value: String?
        }
    }

    public enum DidTapCreateAccountButtonSync {
        public struct Request {}
        
        public struct Response {
            let email: String
            let password: String
        }
        
        public typealias ViewModel = Response
    }
}
