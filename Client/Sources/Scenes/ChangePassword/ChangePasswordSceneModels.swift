import UIKit

public enum ChangePasswordScene {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension ChangePasswordScene.Model {
    
    struct SceneModel {
        var currentPassword: String?
        var newPassword: String?
        var confirmPassword: String?
        var currentPasswordError: CurrentPasswordValidationError?
        var newPasswordError: NewPasswordValidationError?
        var confirmPasswordError: ConfirmPasswordValidationError?
    }
    
    struct SceneViewModel {
        let currentPassword: String?
        let currentPasswordError: String?
        let newPassword: String?
        let newPasswordError: String?
        let confirmPassword: String?
        let confirmPasswordError: String?
    }
    
    public enum CurrentPasswordValidationError {
        case emptyString
    }
    
    public enum NewPasswordValidationError {
        case emptyString
    }
    
    public enum ConfirmPasswordValidationError {
        case passwordsDoNotMatch
        case emptyString
    }
}

// MARK: - Events

extension ChangePasswordScene.Event {
    
    public typealias Model = ChangePasswordScene.Model
    
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
    
    public enum DidEnterCurrentPasswordSync {
        public struct Request {
            let value: String?
        }
    }
    
    public enum DidEnterNewPasswordSync {
        public struct Request {
            let value: String?
        }
    }
    
    public enum DidEnterConfirmPasswordSync {
        public struct Request {
            let value: String?
        }
    }

    public enum DidTapChangeButtonSync {
        public struct Request {}
        
        public struct Response {
            let currentPassword: String
            let newPassword: String
        }
        
        public typealias ViewModel = Response
    }
}
