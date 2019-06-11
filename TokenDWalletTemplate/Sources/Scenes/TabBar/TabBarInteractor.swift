import Foundation

public protocol TabBarBusinessLogic {
    typealias Event = TabBar.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onTabWasSelected(request: Event.TabWasSelected.Request)
}

extension TabBar {
    public typealias BusinessLogic = TabBarBusinessLogic
    
    @objc(TabBarInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = TabBar.Event
        public typealias Model = TabBar.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private var sceneModel: Model.SceneModel
        private let tabProvider: TabProviderProtocol
        
        // MARK: -
        
        init(
            presenter: PresentationLogic,
            sceneModel: Model.SceneModel,
            tabProvider: TabProviderProtocol
            ) {
            
            self.presenter = presenter
            self.sceneModel = sceneModel
            self.tabProvider = tabProvider
        }
        
        // MARK: - Private
        
        private func sendAction(identifier: Model.TabIdentifier) {
            let response = Event.Action.Response(tabIdentifier: identifier)
            self.presenter.presenterAction(response: response)
        }
    }
}

extension TabBar.Interactor: TabBar.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        let tabs = self.tabProvider.getTabs()
        self.sceneModel.tabs = tabs
    
        let selectedTab: Model.TabItem?
        
        if let seletcedTabIdentifier = self.sceneModel.selectedTabIdentifier {
            selectedTab = self.sceneModel.tabs.first(where: { (tab) -> Bool in
                tab.identifier == seletcedTabIdentifier && tab.isSelectable
            })
        } else {
            selectedTab = self.sceneModel.tabs.first { (tab) -> Bool in
                return tab.isSelectable
            }
        }
        self.sceneModel.selectedTab = selectedTab
        
        let response = Event.ViewDidLoad.Response(
            tabs: tabs,
            selectedTab: selectedTab
        )
        self.presenter.presenterViewDidLoad(response: response)
    }
    
    public func onTabWasSelected(request: Event.TabWasSelected.Request) {
        guard let tab = self.sceneModel.tabs.first(where: { (tab) -> Bool in
            return tab.identifier == request.identifier
        }) else {
            return
        }
        
        self.sceneModel.selectedTabIdentifier = request.identifier
        self.sendAction(identifier: tab.identifier)
        if let currentSelectedTab = self.sceneModel.selectedTab,
            tab.identifier == currentSelectedTab.identifier {
            return
        }
        
        if tab.isSelectable {
            self.sceneModel.selectedTab = tab
        }
        
        guard let selectedTab = self.sceneModel.selectedTab else { return }
        let response = Event.TabWasSelected.Response(item: selectedTab)
        self.presenter.presenterTabWasSelected(response: response)
    }
}
