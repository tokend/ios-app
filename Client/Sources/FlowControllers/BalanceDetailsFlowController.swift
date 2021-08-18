import UIKit

class BalanceDetailsFlowController: BaseSignedInFlowController {
    
    typealias OnCloseFlow = () -> Void
    
    // MARK: Private properties
    
    private let balanceId: String
    private let navigationController: NavigationControllerProtocol
    private let onClose: OnCloseFlow
    
    // MARK:
    
    init(
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        reposController: ReposController,
        managersController: ManagersController,
        userDataProvider: UserDataProviderProtocol,
        keychainDataProvider: KeychainDataProviderProtocol,
        rootNavigation: RootNavigationProtocol,
        balanceId: String,
        navigationController: NavigationControllerProtocol,
        onClose: @escaping OnCloseFlow
    ) {
        
        self.balanceId = balanceId
        self.navigationController = navigationController
        self.onClose = onClose
        
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
}

// MARK: Private methods

private extension BalanceDetailsFlowController {
    
    func initBalanceDetails(
        onBack: @escaping () -> Void
    ) -> UIViewController {
        
        let controller: BalanceDetailsScene.ViewController = .init()
        
        let routing: BalanceDetailsScene.Routing = .init(
            onBackAction: onBack
        )
        
        BalanceDetailsScene.Configurator.configure(
            viewController: controller,
            routing: routing
        )
        
        return controller
    }
}

// MARK: Public methods

extension BalanceDetailsFlowController {
    
    func run(
        showRootScreen: (UIViewController) -> Void
    ) {
        
        showRootScreen(
            initBalanceDetails(
                onBack: onClose
            )
        )
    }
}
