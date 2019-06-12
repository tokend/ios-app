import UIKit

public enum TabBar {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension TabBar.Model {
    
    public typealias TabIdentifier = String
    
    public struct SceneModel {
        var tabs: [TabItem]
        var selectedTab: TabItem?
        var selectedTabIdentifier: TabIdentifier?
    }
    
    public struct TabItem {
        let title: String
        let image: UIImage
        let identifier: TabIdentifier
        let isSelectable: Bool
    }
}

// MARK: - Events

extension TabBar.Event {
    public typealias Model = TabBar.Model
    
    // MARK: -
    
    public enum ViewDidLoad {
        public struct Request {}
        public struct Response {
            let tabs: [Model.TabItem]
            let selectedTab: Model.TabItem?
        }
        public typealias ViewModel = Response
    }
    
    public enum TabWasSelected {
        public struct Request {
            let identifier: Model.TabIdentifier
        }
        
        public struct Response {
            let item: Model.TabItem
        }
        public typealias ViewModel = Response
    }
    
    public enum Action {
        public struct Response {
            let tabIdentifier: Model.TabIdentifier
        }
        public typealias ViewModel = Response
    }
}
