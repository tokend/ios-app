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
        (self.navigationController as? NavigationController)?.navigationBar.prefersLargeTitles = true
        
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
        
        let routing: DashboardScene.Routing = .init(
            onAddAsset: { },
            onBalanceTap: { [weak self] (id) in
                self?.showSend(for: id)
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
    
    func showSend(for balanceId: String) {
        
        let flow: SendFlowController = .init(
            appController: self.appController,
            flowControllerStack: self.flowControllerStack,
            reposController: self.reposController,
            managersController: self.managersController,
            userDataProvider: self.userDataProvider,
            keychainDataProvider: self.keychainDataProvider,
            rootNavigation: self.rootNavigation,
            navigationController: self.navigationController,
            balanceId: balanceId,
            onClose: { [weak self] in
                let _ = self?.navigationController.popToRootViewController(animated: true)
                self?.currentFlowController = nil
            }
        )
        
        self.currentFlowController = flow
        flow.run(showRootScreen: { (controller) in
            self.navigationController.pushViewController(controller, animated: true)
        })
    }
}
