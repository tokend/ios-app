import UIKit

public enum TabsContainer {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension TabsContainer.Model {
    
    public typealias TabIdentifier = String
    
    public class SceneModel {
        
        public var tabs: [TabModel]
        public var selectedTabId: TabIdentifier?
        
        public init() {
            self.tabs = []
            self.selectedTabId = nil
        }
    }
    
    public struct TabModel: Equatable {
        
        public let title: String
        public let content: TabContent
        public let identifier: TabIdentifier
        
        public init(
            title: String,
            content: TabContent,
            identifier: TabIdentifier
            ) {
            
            self.title = title
            self.content = content
            self.identifier = identifier
        }
    }
    
    public typealias TabViewModel = TabModel
    
    public enum TabContent: Equatable {
        
        case viewController(UIViewController)
    }
}

// MARK: - Events

extension TabsContainer.Event {
    
    public typealias Model = TabsContainer.Model
    
    // MARK: -
    
    public enum ViewDidLoad {
        
        public struct Request {}
    }
    
    public enum TabsUpdated {
        
        public struct Response {
            
            public let tabs: [Model.TabModel]
            public let selectedTabIndex: Int?
            
            public init(
                tabs: [Model.TabModel],
                selectedTabIndex: Int?
                ) {
                
                self.tabs = tabs
                self.selectedTabIndex = selectedTabIndex
            }
        }
        
        public typealias ViewModel = Response
    }
    
    public enum TabWasSelected {
        
        public  struct Request {
            
            public let identifier: Model.TabIdentifier
            
            public init(identifier: Model.TabIdentifier) {
                self.identifier = identifier
            }
        }
        
        public struct Response {
            
            public let selectedTabIndex: Int
            
            public init(selectedTabIndex: Int) {
                self.selectedTabIndex = selectedTabIndex
            }
        }
        
        public typealias ViewModel = Response
    }
}
