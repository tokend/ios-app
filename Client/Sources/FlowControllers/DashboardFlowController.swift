import Foundation
import TokenDSDK

class DashboardFlowController: BaseSignedInFlowController {
    
    // MARK: - Private properties

    private lazy var rootViewController: DashboardScene.ViewController = initDashboard()
    private let navigationController: NavigationControllerProtocol
    
    // MARK: -

    init(
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        reposController: ReposController,
        managersController: ManagersController,
        userDataProvider: UserDataProviderProtocol,
        keychainDataProvider: KeychainDataProviderProtocol,
        rootNavigation: RootNavigationProtocol,
        navigationController: NavigationControllerProtocol
    ) {

        self.navigationController = navigationController
        (navigationController.getViewController() as? UINavigationController)?.navigationBar.prefersLargeTitles = true
        
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
    
    // MARK: - Public

    public func run(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        showRootScreen?(rootViewController)
    }
}

// MARK: - Private methods

private extension DashboardFlowController {
    
    func initDashboard(
    ) -> DashboardScene.ViewController {
        let vc: DashboardScene.ViewController = .init()
        vc.navigationItem.largeTitleDisplayMode = .always
        
        let routing: DashboardScene.Routing = .init(
            onAddAsset: { },
            onBalanceTap: { [weak self] (id) in
                self?.showBalanceDetailsFlow(
                    balanceId: id
                )
            }
        )
        
        let balancesProvider: DashboardScene.BalancesProviderProtocol = DashboardScene.BalancesProvider(
            assetsRepo: reposController.assetsRepo,
            balancesRepo: reposController.balancesRepo,
            imagesUtility: reposController.imagesUtility
        )
        
        DashboardScene.Configurator.configure(
            viewController: vc,
            routing: routing,
            balancesProvider: balancesProvider
        )
        
        return vc
    }
    
    func showBalanceDetailsFlow(
        balanceId: String
    ) {
        
        let flow = initBalanceDetailsFlow(
            balanceId: balanceId
        )
        
        flow.run(
            showRootScreen: { [weak self] (controller) in
                self?.navigationController.pushViewController(controller, animated: true)
            }
        )
        
        self.currentFlowController = flow
    }
    
    func initBalanceDetailsFlow(
        balanceId: String
    ) -> BalanceDetailsFlowController {
        
        let currentController: UIViewController? = navigationController.topViewController
        let flow: BalanceDetailsFlowController = .init(
            appController: appController,
            flowControllerStack: flowControllerStack,
            reposController: reposController,
            managersController: managersController,
            userDataProvider: userDataProvider,
            keychainDataProvider: keychainDataProvider,
            rootNavigation: rootNavigation,
            balanceId: balanceId,
            navigationController: navigationController,
            onClose: { [weak self] in
                if let current = currentController {
                    self?.navigationController.popToViewController(current, animated: true)
                } else {
                    _ = self?.navigationController.popViewController(true)
                }
                self?.currentFlowController = nil
            }
        )

        return flow
    }
}
