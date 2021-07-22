import UIKit

public enum TabBar {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

public extension TabBar.Model {
    
    typealias TabIdentifier = String
    
    struct SceneModel {
        var tabs: [TabItem]
        var selectedTabIdentifier: TabIdentifier?
    }
    
    struct SceneViewModel {
        let tabs: [TabBar.TabBarItem]
        let selectedTab: TabBar.TabBarItem?
    }
    
    struct TabItem {
        let title: String
        let image: UIImage
        let identifier: TabIdentifier
    }
}

// MARK: - Events

public extension TabBar.Event {
    typealias Model = TabBar.Model
    
    // MARK: -
    
    enum ViewDidLoad {
        public struct Request {}
    }

    enum ViewDidLoadSync {
        public struct Request {}
    }
    
    enum SceneDidUpdate {
        public struct Response {
            let sceneModel: Model.SceneModel
            let animated: Bool
        }

        public struct ViewModel {
            let viewModel: Model.SceneViewModel
            let animated: Bool
        }
    }
    
    enum SceneDidUpdateSync {
        public struct Response {
            let sceneModel: Model.SceneModel
            let animated: Bool
        }

        public struct ViewModel {
            let viewModel: Model.SceneViewModel
            let animated: Bool
        }
    }
    
    enum DidSelectTabSync {
        public struct Request {
            let identifier: Model.TabIdentifier
            let shouldChangeSelectedTab: Bool
        }
    }
}
