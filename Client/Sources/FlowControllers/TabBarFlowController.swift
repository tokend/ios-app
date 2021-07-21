import UIKit
import TokenDSDK
import RxSwift

class TabBarFlowController: BaseSignedInFlowController {
    
    typealias OnSignOut = () -> Void
    typealias ShowContent = (UIViewController, TabContentContainer.ViewController.Animation) -> Void

    enum Tab: String {
        case balances
        case movements
    }
    
    // MARK: - Private properties

    private let navigationController: NavigationControllerProtocol = NavigationController()
    private var tabBarScene: TabBarContainer.ViewController?
    private var contentContainer: TabContentContainer.ViewController?
    private var selectedTab: Tab?
    private var firstInitialization: Bool = true
    private let onAskSignOut: OnSignOut
    private let onPerformSignOut: OnSignOut
    private let tabsOrder: [Tab] = [
        .balances,
        .movements
    ]
    
    private lazy var tabBar: TabBar.View = .init()
    
    init(
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        reposController: ReposController,
        managersController: ManagersController,
        userDataProvider: UserDataProviderProtocol,
        keychainDataProvider: KeychainDataProviderProtocol,
        rootNavigation: RootNavigationProtocol,
        onAskSignOut: @escaping OnSignOut,
        onPerformSignOut: @escaping OnSignOut
    ) {
        self.onAskSignOut = onAskSignOut
        self.onPerformSignOut = onPerformSignOut
        super.init(
            appController: appController,
            flowControllerStack: flowControllerStack,
            reposController: reposController,
            managersController: managersController,
            userDataProvider: userDataProvider,
            keychainDataProvider: keychainDataProvider,
            rootNavigation: rootNavigation
        )
    }
    
    override func performTFA(tfaInput: ApiCallbacks.TFAInput, cancel: @escaping () -> Void) {
        self.currentFlowController?.performTFA(tfaInput: tfaInput, cancel: cancel)
    }
}

// MARK: - Private methods

private extension TabBarFlowController {
    
    func showTabBar(
        showRootScreen: ((_ vc: RootContentProtocol) -> Void)?,
        selectedTab: Tab?
    ) {

        self.selectedTab = selectedTab
        let selectedTabIdentifier = selectedTab?.rawValue

        let container = TabBarContainer.ViewController()

        let contentContainer: TabContentContainer.ViewController = .init()
        let tabContentContainerRouting: TabContentContainer.Routing = .init()
        TabContentContainer.Configurator.configure(
            viewController: contentContainer,
            routing: tabContentContainerRouting
        )
        container.content = contentContainer
        
        let tabProvider: TabBar.TabProviderProtocol = TabBar.TabProvider(
            order: self.tabsOrder
        )

        let showContent: ShowContent = { [weak contentContainer] (controller, animation) in
            contentContainer?.setContent(controller, animation: animation)
        }

        let tabBarRouting: TabBar.Routing = .init(
            onTabSelected: { [weak self] (identifier) -> Bool in
                return self?.showSelectedTab(
                    identifier,
                    order: self?.tabsOrder ?? [],
                    showContent: showContent,
                    animated: true
                ) ?? false
        })
        
        TabBar.Configurator.configure(
            view: tabBar,
            selectedTabIdentifier: selectedTabIdentifier,
            tabProvider: tabProvider,
            routing: tabBarRouting
        )
        container.tabBar = tabBar

        let tabBarContainerRouting = TabBarContainer.Routing()
        tabBarScene = container
        self.contentContainer = contentContainer
        TabBarContainer.Configurator.configure(
            viewController: container,
            routing: tabBarContainerRouting
        )

        self.navigationController.setViewControllers([container], animated: false)
        navigationController.setNavigationBarHidden(true, animated: false)

        showSelectedTab(
            selectedTabIdentifier,
            order: self.tabsOrder,
            showContent: showContent,
            animated: false
        )

        if let showRoot = showRootScreen {
            showRoot(self.navigationController)
        } else {
            self.rootNavigation.setRootContent(self.navigationController, transition: .fade, animated: false)
        }
    }
    
    /// - Returns: true if should change selected tab
    @discardableResult
    func showSelectedTab(
        _ identifier: TabBar.Model.TabIdentifier?,
        order: [Tab],
        showContent: @escaping (UIViewController, TabContentContainer.ViewController.Animation) -> Void,
        animated: Bool
    ) -> Bool {

        guard let identifier = identifier,
            let tab = Tab(rawValue: identifier)
            else {
                return false
        }
        
        if selectedTab == tab && !firstInitialization {
            return false
        }

        firstInitialization = false

        let animation: TabContentContainer.ViewController.Animation

        if animated,
            let previousTab = selectedTab,
            let previousIndex = order.indexOf(previousTab),
            let newIndex = order.indexOf(tab) {

            if previousIndex < newIndex {
                animation = .leftToRight
            } else if previousIndex > newIndex {
                animation = .rightToLeft
            } else {
                animation = .none
            }
        } else {
            animation = .none
        }
        
        switch tab {
        
        case .balances:
            selectedTab = tab
            showBalancesFlow(showRootScreen: { (controller) in
                showContent(controller, animation)
            })
            return true
            
        case .movements:
            selectedTab = tab
            showMovementsFlow(showRootScreen: { (controller) in
                showContent(controller, animation)
            })
            return true
        }
    }
    
    func showBalancesFlow(
        showRootScreen: @escaping (UIViewController) -> Void
    ) {
        
        let controller: UIViewController = .init()
        controller.view.backgroundColor = .red
        showRootScreen(controller)
    }
    
    func showMovementsFlow(
        showRootScreen: @escaping (UIViewController) -> Void
    ) {
        
        let controller: UIViewController = .init()
        controller.view.backgroundColor = .blue
        showRootScreen(controller)
    }
}

// MARK: - Public methods

extension TabBarFlowController {

    public func run(
        showRootScreen: ((_ vc: RootContentProtocol) -> Void)?,
        selectedTab: Tab?
    ) {

        showTabBar(
            showRootScreen: showRootScreen,
            selectedTab: selectedTab
        )
    }
}
