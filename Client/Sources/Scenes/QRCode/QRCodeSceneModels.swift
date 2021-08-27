import UIKit

public enum QRCodeScene {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension QRCodeScene.Model {
    
    struct SceneModel {
        let title: String
        var data: String
    }
    
    struct SceneViewModel {
        let screenTitle: String
        let qrCodeValue: String
    }
}

// MARK: - Events

extension QRCodeScene.Event {
    
    public typealias Model = QRCodeScene.Model
    
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
        public typealias ViewModel = Response
    }
}
