import UIKit

public enum LocalSignInScene {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension LocalSignInScene.Model {
    
    struct SceneModel {
        var avatarUrl: String?
        var login: String
        var password: String?
        var passwordError: PasswordError?
        var biometricsType: BiometricsType
    }
    
    struct SceneViewModel {
        let avatarUrl: String?
        let avatarTitle: String
        let login: String
        let password: String?
        let passwordError: String?
        let biometricsTitle: String?
        let biometricsImage: UIImage?
    }
    
    public enum PasswordError {
        case empty
    }
    
    public enum BiometricsType {

        case faceId
        case touchId
        case none
    }
}

// MARK: - Events

extension LocalSignInScene.Event {
    
    public typealias Model = LocalSignInScene.Model
    
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
    
    public enum DidEnterPasswordSync {
        public struct Request {
            let value: String?
        }
    }
    
    public enum DidTapBiometricsSync {
        public struct Request {}
        public struct Response {}
        public typealias ViewModel = Response
    }
    
    public enum DidTapLoginButtonSync {
        public struct Request {}
        public struct Response {
            let password: String
        }
        public typealias ViewModel = Response
    }
}
