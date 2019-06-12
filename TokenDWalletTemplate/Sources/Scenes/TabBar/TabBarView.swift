import UIKit

public protocol TabBarDisplayLogic: class {
    typealias Event = TabBar.Event
    
    func displayViewDidLoad(viewModel: Event.ViewDidLoad.ViewModel)
    func displayTabWasSelected(viewModel: Event.TabWasSelected.ViewModel)
    func displayAction(viewModel: Event.Action.ViewModel)
}

extension TabBar {
    public typealias DisplayLogic = TabBarDisplayLogic
    
    @objc(TabBarView)
    public class View: UITabBar {
        
        public typealias Event = TabBar.Event
        public typealias Model = TabBar.Model
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        private var onDeinit: DeinitCompletion = nil
        
        public func inject(
            interactorDispatch: InteractorDispatch?,
            routing: Routing?,
            onDeinit: DeinitCompletion = nil
            ) {
            
            self.interactorDispatch = interactorDispatch
            self.routing = routing
            self.onDeinit = onDeinit
            
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        // MARK: - Overridden
        
        public override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.delegate = self
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - Private
        
        private func getTabBarItem(identifier: Model.TabIdentifier) -> UITabBarItem? {
            return self.items?.compactMap({ (item) -> TabBar.TabBarItem? in
                return item as? TabBar.TabBarItem
            }).first(where: { (tab) -> Bool in
                return tab.identifier == identifier
            })
        }
    }
}
    
extension TabBar.View: TabBar.DisplayLogic {
    
    public func displayViewDidLoad(viewModel: Event.ViewDidLoad.ViewModel) {
        let items = viewModel.tabs.map { (tab) -> TabBar.TabBarItem in
            return TabBar.TabBarItem(
                title: tab.title,
                image: tab.image,
                identifier: tab.identifier
            )
        }
        self.items = items
        if let seletcedItemIdentifier = viewModel.selectedTab?.identifier {
            let seletcedItem = self.getTabBarItem(identifier: seletcedItemIdentifier)
            self.selectedItem = seletcedItem
        }
    }
    
    public func displayTabWasSelected(viewModel: Event.TabWasSelected.ViewModel) {
        let seletcedItem = self.getTabBarItem(identifier: viewModel.item.identifier)
        self.selectedItem = seletcedItem
    }
    
    public func displayAction(viewModel: Event.Action.ViewModel) {
        self.routing?.onAction(viewModel.tabIdentifier)
    }
}

extension TabBar.View: UITabBarDelegate {
    
    public func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let tabBarItem = item as? TabBar.TabBarItem else {
            return
        }
        let request = Event.TabWasSelected.Request(identifier: tabBarItem.identifier)
        self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
            businessLogic.onTabWasSelected(request: request)
        })
    }
}

extension TabBar.View: TabBarContainerTabBarProtocol {
    
    public func setSelectedTabWithIdentifier(_ identifier: TabBarContainer.TabIdentifier) {
        let request = Event.TabWasSelected.Request(identifier: identifier)
        self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
            businessLogic.onTabWasSelected(request: request)
        })
    }
    
    public var view: UIView {
        return self
    }
    
    public var height: CGFloat {
        return self.frame.height
    }
}
