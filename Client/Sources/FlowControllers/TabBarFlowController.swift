import UIKit
import TokenDSDK
import RxSwift

class TabBarFlowController: BaseSignedInFlowController {
    
    typealias OnSignOut = () -> Void
    typealias ShowContent = (UIViewController, TabContentContainer.ViewController.Animation) -> Void

    enum Tab: String {
        case balances
        case movements
        case more
    }
    
    // MARK: - Private properties

    private lazy var moreTabNavigationController: NavigationControllerProtocol = initMoreFlow()
    
    private var dashboardFlow: DashboardFlowController?
    private lazy var balancesTabNavigationController: NavigationControllerProtocol = initBalancesNavigationController()
    
    private var tabBarScene: TabBarContainer.ViewController?
    private var contentContainer: TabContentContainer.ViewController?
    private var selectedTab: Tab?
    private var firstInitialization: Bool = true
    private let onAskSignOut: OnSignOut
    private let onPerformSignOut: OnSignOut
    private let tabsOrder: [Tab] = [
        .balances,
        .movements,
        .more
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
    
    override func handleTFASecret(_ secret: String, seed: String, completion: @escaping (Bool) -> Void) {
        self.currentFlowController?.handleTFASecret(secret, seed: seed, completion: completion)
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
        
        showSelectedTab(
            selectedTabIdentifier,
            order: self.tabsOrder,
            showContent: showContent,
            animated: false
        )

        if let showRoot = showRootScreen {
            showRoot(container)
        } else {
            self.rootNavigation.setRootContent(container, transition: .fade, animated: false)
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
            currentFlowController = dashboardFlow
            showDashboard(showRootScreen: { (controller) in
                showContent(controller, animation)
            })
            return true
            
        case .movements:
            selectedTab = tab
            currentFlowController = nil
            showMovementsFlow(showRootScreen: { (controller) in
                showContent(controller, animation)
            })
            return true
            
        case .more:
            selectedTab = tab
            currentFlowController = nil
            showMoreFlow(showRootScreen: { (controller) in
                showContent(controller, animation)
            })
            return true
        }
    }
    
    func showDashboard(
        showRootScreen: @escaping (UIViewController) -> Void
    ) {
        
        showRootScreen(balancesTabNavigationController.getViewController())
    }
    
    func initDashboardFlow(
        navigationController: NavigationControllerProtocol
    ) -> DashboardFlowController {
        
        .init(
            appController: self.appController,
            flowControllerStack: self.flowControllerStack,
            reposController: self.reposController,
            managersController: self.managersController,
            userDataProvider: self.userDataProvider,
            keychainDataProvider: self.keychainDataProvider,
            rootNavigation: self.rootNavigation,
            navigationController: navigationController
        )
    }
    
    func initBalancesNavigationController(
    ) -> NavigationControllerProtocol {
        
        let navigationController: NavigationControllerProtocol = NavigationController()
        dashboardFlow = initDashboardFlow(
            navigationController: navigationController
        )
        
        dashboardFlow?.run(showRootScreen: { (viewController) in
            navigationController.setViewControllers([viewController], animated: false)
        })
        return navigationController
    }
    
    func showMovementsFlow(
        showRootScreen: @escaping (UIViewController) -> Void
    ) {
        
        let controller: UIViewController = .init()
        controller.view.backgroundColor = .blue
        showRootScreen(controller)
    }
    
    func showMoreFlow(
        showRootScreen: @escaping (UIViewController) -> Void
    ) {
        
        showRootScreen(moreTabNavigationController.getViewController())
    }
    
    func initMoreFlow(
    ) -> NavigationControllerProtocol {
        
        let navigationController: NavigationControllerProtocol = NavigationController()
        
        let controller: MoreScene.ViewController = .init()
        controller.navigationItem.title = Localized(.more_scene_title)
        
        let routing: MoreScene.Routing = .init(
            onUserTap: { [weak self] in
                self?.showAccountId(in: navigationController)
            },
            onDepositTap: {},
            onWithdrawTap: {},
            onExploreSalesTap: {},
            onTradeTap: {},
            onPollsTap: {},
            onSettingsTap: { [weak self] in
                self?.showSettingsFlow(
                    navigationController: navigationController
                )
            }
        )
        
        let userDataProvider: MoreScene.UserDataProvider = .init(
            userDataProvider: userDataProvider,
            accountTypeManager: managersController.accountTypeManager,
            activeKYCRepo: reposController.activeKycRepo,
            imagesUtility: reposController.imagesUtility
        )
        
        MoreScene.Configurator.configure(
            viewController: controller,
            routing: routing,
            userDataProvider: userDataProvider
        )
        
        navigationController.setViewControllers([controller], animated: false)
        controller.navigationController?.navigationBar.prefersLargeTitles = true
        
        return navigationController
    }
    
    func showAccountId(in navigationController: NavigationControllerProtocol) {
        
        navigationController.pushViewController(
            initAccountId(
                onBack: {
                    navigationController.popViewController(true)
                }
            ),
            animated: true
        )
    }
    
    func initAccountId(
        onBack: @escaping () -> Void
    ) -> UIViewController {
        
        let viewController: QRCodeScene.ViewController = .init()
        viewController.hidesBottomBarWhenPushed = true
        
        let routing: QRCodeScene.Routing = .init(
            onBackAction: onBack,
            onShare: { [weak self] (valueToShare) in
                self?.shareValue(
                    valueToShare,
                    on: viewController
                )
            }
        )
        
        let accountIdProvider: QRCodeScene.LoginDataProvider = .init(
            userDataProvider: userDataProvider
        )
        
        QRCodeScene.Configurator.configure(
            viewController: viewController,
            routing: routing,
            dataProvider: accountIdProvider
        )
        
        return viewController
    }
    
    func shareValue(
        _ value: String,
        on viewController: UIViewController
    ) {
        
        let activity: UIActivityViewController = .init(
            activityItems: [value],
            applicationActivities: nil
        )
        
        viewController.present(
            activity,
            animated: true,
            completion: nil
        )
    }
    
    func showSettingsFlow(
        navigationController: NavigationControllerProtocol
    ) {
        
        let flow = initSettingsFlow(navigationController: navigationController)
        self.currentFlowController = flow
        flow.run(showRootScreen: { (controller) in
            navigationController.pushViewController(controller, animated: true)
            controller.navigationController?.navigationBar.prefersLargeTitles = true
        })
    }
    
    func initSettingsFlow(
        navigationController: NavigationControllerProtocol
    ) -> SettingsFlowController {
        
        return .init(
            appController: self.appController,
            flowControllerStack: self.flowControllerStack,
            reposController: self.reposController,
            managersController: self.managersController,
            userDataProvider: self.userDataProvider,
            keychainDataProvider: self.keychainDataProvider,
            rootNavigation: self.rootNavigation,
            navigationController: navigationController,
            onAskSignOut: { [weak self] in
                self?.onAskSignOut()
            },
            onBackAction: { [weak self] in
                navigationController.popViewController(true)
                self?.currentFlowController = nil
            }
        )
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
