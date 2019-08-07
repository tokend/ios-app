import Foundation

enum SaleInfo {
    
    // MARK: - Typealiases
    typealias Identifier = String
    
    // MARK: -
    
    enum Model {}
    enum Event {}
}

// MARK: - Models

extension SaleInfo.Model {
    
    class SceneModel {
        var tabs: [TabModel]
        var selectedTabId: SaleInfo.Identifier?
        
        init(tabs: [TabModel]) {
            self.tabs = tabs
        }
    }
    
    struct TabModel {
        let title: String
        let contentModel: Any
    }
    
    struct TabViewModel {
        let title: String
        let contentViewModel: Any
    }
}

// MARK: - Events

extension SaleInfo.Event {
    enum OnViewDidLoad {
        struct Request {}
    }
    
    enum OnTabsUpdated {
        struct Response {
            let tabTitles: [String]
            let selectedIndex: Int?
            let contentModel: Any
        }
        
        struct ViewModel {
            let tabTitles: [String]
            let selectedIndex: Int?
            let contentViewModel: Any
        }
    }
    
    enum TabDidChange {
        struct Request {
            let id: SaleInfo.Identifier
        }
        
        struct Response {
            let tab: SaleInfo.Model.TabModel
        }
        
        struct ViewModel {
            let tab: SaleInfo.Model.TabViewModel
        }
    }
}
