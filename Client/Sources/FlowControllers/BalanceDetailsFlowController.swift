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
    
    @objc func closeSelector() {
        onClose()
    }
    
    func initBalanceDetails(
        backTarget: Any?,
        backAction: Selector?
    ) -> UIViewController {
        
        let controller: BalanceDetailsScene.ViewController = .init()
        controller.navigationItem.largeTitleDisplayMode = .never
        
        if let target = backTarget,
           let action = backAction {
            controller.navigationItem.leftBarButtonItems = [
                .init(
                    image: Assets.arrow_back_icon.image,
                    style: .plain,
                    target: target,
                    action: action
                )
            ]
        }
        
        let routing: BalanceDetailsScene.Routing = .init(
            onDidSelectTransaction: { (transactionId) in },
            onReceive: { },
            onSend: { [weak self] in
                self?.showSendFlow()
            }
        )
        
        let balanceProvider: BalanceDetailsScene.BalanceProvider = .init(
            balanceId: balanceId,
            assetsRepo: reposController.assetsRepo,
            balancesRepo: reposController.balancesRepo,
            imagesUtility: managersController.imagesUtility
        )
        
        let transactionsProvider: BalanceDetailsScene.TransactionsProvider = .init(
            movementsRepo: reposController.movementsRepo(
                for: balanceId
            ),
            receiverAccountId: userDataProvider.walletData.accountId
        )
        
        BalanceDetailsScene.Configurator.configure(
            viewController: controller,
            routing: routing,
            balanceProvider: balanceProvider,
            transactionsProvider: transactionsProvider
        )
        
        return controller
    }
    
    func showSendFlow() {
        let flow = initSendFlow()
        self.currentFlowController = flow
        flow.run(
            showRootScreen: { [weak self] (controller) in
                self?.navigationController.pushViewController(controller, animated: true)
            }
        )
    }
    
    func initSendFlow() -> SendFlowController {
        
        let currentController: UIViewController? = navigationController.topViewController
        
        return .init(
            appController: self.appController,
            flowControllerStack: self.flowControllerStack,
            reposController: self.reposController,
            managersController: self.managersController,
            userDataProvider: self.userDataProvider,
            keychainDataProvider: self.keychainDataProvider,
            rootNavigation: self.rootNavigation,
            navigationController: self.navigationController,
            balanceId: self.balanceId,
            onClose: { [weak self] in
                if let current = currentController {
                    self?.navigationController.popToViewController(current, animated: true)
                } else {
                    _ = self?.navigationController.popViewController(true)
                }
                self?.currentFlowController = nil
            }
        )
    }
}

// MARK: Public methods

extension BalanceDetailsFlowController {
    
    func run(
        showRootScreen: (UIViewController) -> Void
    ) {
        
        showRootScreen(
            initBalanceDetails(
                backTarget: self,
                backAction: #selector(closeSelector)
            )
        )
    }
}
