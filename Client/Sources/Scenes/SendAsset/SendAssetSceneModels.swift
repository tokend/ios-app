import UIKit

public enum SendAssetScene {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension SendAssetScene.Model {
    
    struct SceneModel {
        var recipientAddress: String?
        var recipientError: RecipientValidationError?
    }
    
    struct SceneViewModel {
        let recipientAddress: String?
        let recipientError: String?
    }
    
    public enum RecipientValidationError {
        case emptyString
    }
}

// MARK: - Events

extension SendAssetScene.Event {
    
    public typealias Model = SendAssetScene.Model
    
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
    
    public enum DidEnterRecipientSync {
        public struct Request {
            let value: String?
        }
    }
    
    public enum DidTapContinueSync {
        public struct Request {}
        
        public struct Response {
            let recipient: String
        }
        public typealias ViewModel = Response
    }
}
