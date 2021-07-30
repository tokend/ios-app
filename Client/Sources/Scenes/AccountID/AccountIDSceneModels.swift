import UIKit

public enum AccountIDScene {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension AccountIDScene.Model {
    
    struct SceneModel {
        var accountId: String
    }
    
    struct SceneViewModel {
        let qrCodeValue: String
    }
}

// MARK: - Events

extension AccountIDScene.Event {
    
    public typealias Model = AccountIDScene.Model
    
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
    
    public enum DidTapShareSync {
        public struct Request { }
        public struct Response {
            let value: String
        }
        public struct ViewModel {
            let value: String
        }
    }
}
