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
    
    public struct SceneContent {
        let content: TabBarContainer.ContentProtocol
        let tabBar: TabBarContainer.TabBarProtocol
        let title: String
    }
}

// MARK: - Events

extension TabBarContainer.Event {
    public typealias Model = TabBarContainer.Model
    
    // MARK: -
    
    public enum ViewDidLoad {
        public struct Request {}
        public struct Response {
            let sceneContent: Model.SceneContent
        }
        public typealias ViewModel = Response
    }
}
