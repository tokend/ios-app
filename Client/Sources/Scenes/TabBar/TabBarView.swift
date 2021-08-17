import UIKit

public protocol TabBarDisplayLogic: AnyObject {
    typealias Event = TabBar.Event
    
    func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel)
    func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel)
}

extension TabBar {
    public typealias DisplayLogic = TabBarDisplayLogic
    
    @objc(TabBarView)
    public class View: UIView {
        
        public typealias Event = TabBar.Event
        public typealias Model = TabBar.Model

        // MARK: - Private properties

        private let tabBar: UITabBar = .init()
        
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

            let requestSync = Event.ViewDidLoadSync.Request()
            self.interactorDispatch?.sendSyncRequest { businessLogic in
                businessLogic.onViewDidLoadSync(request: requestSync)
            }
        }
        
        // MARK: - Overridden
        
        public override init(frame: CGRect) {
            super.init(frame: frame)
            
            commonInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)

            commonInit()
        }
    }
}

// MARK: - Private methods

private extension TabBar.View {

    func commonInit() {

        setupTabBar()
        setupLayout()
    }

    func setupTabBar() {

        tabBar.delegate = self
        tabBar.barStyle = .default
        tabBar.isTranslucent = true
    }

    func setupLayout() {

        view.addSubview(tabBar)

        tabBar.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalToSuperview()
            make.bottom.equalTo(view.safeArea.bottom)
        }
    }
    
    func setup(with sceneViewModel: Model.SceneViewModel, animated: Bool) {
        
        tabBar.setItems(sceneViewModel.tabs, animated: false)
        tabBar.selectedItem = sceneViewModel.selectedTab
    }
}

// MARK: - UITabBarDelegate

extension TabBar.View: UITabBarDelegate {
    
    public func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let tabBarItem = item as? TabBar.TabBarItem
            else {
                return
        }
        
        guard let shouldChangeSelectedTab = routing?.onTabSelected(tabBarItem.identifier)
        else {
            return
        }
        
        let request = Event.DidSelectTabSync.Request(
            identifier: tabBarItem.identifier,
            shouldChangeSelectedTab: shouldChangeSelectedTab
        )
        
        self.interactorDispatch?.sendSyncRequest(requestBlock: { (businessLogic) in
            businessLogic.onDidSelectTabSync(request: request)
        })
    }
}

extension TabBar.View: TabBarContainerTabBarProtocol {

    public var view: UIView {
        return self
    }
    
    public var height: CGFloat {
        return self.frame.height
    }
}

// MARK: - TabBar.DisplayLogic
    
extension TabBar.View: TabBar.DisplayLogic {
    
    public func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
    
    public func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
}
