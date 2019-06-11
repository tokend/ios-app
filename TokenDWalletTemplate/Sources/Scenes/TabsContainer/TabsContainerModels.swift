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
        
        public init(selectedTabId: TabIdentifier? = nil) {
            self.tabs = []
            self.selectedTabId = selectedTabId
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
    
    public struct ViewConfig {
        let isPickerHidden: Bool
        let isTabBarHidden: Bool
        let actionButtonAppearence: ActionButtonAppearence
        let isScrollEnabled: Bool
    }
    
    public enum ActionButtonAppearence {
        case visible(title: String)
        case hidden
    }
    
    public enum TabItemConfiguration {
        case storeState(TabIdentifier)
        case transfer(onSelect: () -> Void)
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
        
        public struct Request {
            
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
    
    public enum TabScrolled {
        
        public struct Request {
            
            public let tabIndex: Int
            
            public init(tabIndex: Int) {
                self.tabIndex = tabIndex
            }
        }
    }
    
    public enum SelectedTabChanged {
        
        public struct Response {
            
            public let selectedTabIndex: Int
            
            public init(selectedTabIndex: Int) {
                self.selectedTabIndex = selectedTabIndex
            }
        }
        
        public typealias ViewModel = Response
    }
}
