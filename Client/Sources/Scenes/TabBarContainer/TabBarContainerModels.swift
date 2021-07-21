import UIKit

public enum TabBarContainer {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension TabBarContainer.Model {
    
    struct SceneModel {
        
        var projectName: String?
    }
    
    struct SceneViewModel {
        
        let screenTitle: String?
    }
}

// MARK: - Events

extension TabBarContainer.Event {
    
    public typealias Model = TabBarContainer.Model
    
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
}
