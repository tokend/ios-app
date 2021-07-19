import UIKit

public enum SignInScene {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension SignInScene.Model {
    
    struct SceneModel {
        var network: String?
        var login: String?
        var password: String?
        var networkError: NetworkValidationError?
        var loginError: LoginValidationError?
        var passwordError: PasswordValidationError?
    }
    
    struct SceneViewModel {
        let network: String?
        let login: String?
        let password: String?
        let networkError: String?
        let loginError: String?
        let passwordError: String?
    }
    
    public enum NetworkValidationError {
        case emptyString
    }
    
    public enum LoginValidationError {
        case doesNotMatchRequirements
        case emptyString
    }
    
    public enum PasswordValidationError {
        case doesNotMatchRequirements
        case emptyString
    }
}

// MARK: - Events

extension SignInScene.Event {
    
    public typealias Model = SignInScene.Model
    
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
    
    public enum DidEnterLoginSync {
        public struct Request {
            let value: String?
        }
    }
    
    public enum DidEnterPasswordSync {
        public struct Request {
            let value: String?
        }
    }

    public enum DidTapLoginButtonSync {
        public struct Request {}
        
        public struct Response {
            let login: String
            let password: String
        }
        
        public typealias ViewModel = Response
    }
}
