import UIKit

class WalletDetailsFlowController: BaseSignedInFlowController {
    
    typealias Identifier = TransactionsListScene.Identifier
    typealias BalanceId = TransactionsListScene.BalanceId
    
    // MARK: - Private properties
    
    private let navigationController: NavigationControllerProtocol = NavigationController()
    
    // MARK: - Public
    
    public func run(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        self.showWalletScreen(showRootScreen: showRootScreen)
    }
    
    // MARK: - Private
    
    private func showWalletScreen(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        let transactionsListRateProvider: TransactionsListScene.RateProviderProtocol = RateProvider(
            assetPairsRepo: self.reposController.assetPairsRepo
        )
        let transactionsFetcher = TransactionsListScene.PaymentsFetcher(
            reposController: self.reposController,
            rateProvider: transactionsListRateProvider,
            originalAccountId: self.userDataProvider.walletData.accountId
        )
        
        let onDidSelectItemWithIdentifier: (Identifier, BalanceId) -> Void = { [weak self] (identifier, balanceId) in
            self?.showTransactionDetailsScreen(transactionId: identifier, balanceId: balanceId)
        }
        
        let showSendPayment:(_ balanceId: String?) -> Void = { [weak self] (balanceId) in
            self?.runSendPaymentFlow(balanceId: balanceId)
        }
        
        let balancesFetcher = BalancesFetcher(
            balancesRepo: self.reposController.balancesRepo
        )
        let headerRateProvider: BalanceHeaderWithPicker.RateProviderProtocol = RateProvider(
            assetPairsRepo: self.reposController.assetPairsRepo
        )
        
        let container = SharedSceneBuilder.createWalletScene(
            transactionsFetcher: transactionsFetcher,
            headerRateProvider: headerRateProvider,
            balancesFetcher: balancesFetcher,
            onDidSelectItemWithIdentifier: onDidSelectItemWithIdentifier,
            showSendPayment: showSendPayment
        )
        
        self.navigationController.setViewControllers([container], animated: false)
        
        if let showRoot = showRootScreen {
            showRoot(self.navigationController.getViewController())
        } else {
            self.rootNavigation.setRootContent(self.navigationController, transition: .fade, animated: false)
        }
    }
    
    private func showTransactionDetailsScreen(
        transactionId: UInt64,
        balanceId: String
        ) {
        let vc = self.setupTransactionDetailsScreen(
            transactionId: transactionId,
            balanceId: balanceId
        )
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupTransactionDetailsScreen(
        transactionId: UInt64,
        balanceId: String
        ) -> TransactionDetails.ViewController {
        
        let routing = TransactionDetails.Routing(
            successAction: { [weak self] in
                self?.navigationController.popViewController(true)
            },
            showProgress: { [weak self] in
                self?.navigationController.showProgress()
            },
            hideProgress: { [weak self] in
                self?.navigationController.hideProgress()
            },
            showError: { [weak self] (error) in
                self?.navigationController.showErrorMessage(error, completion: nil)
        })
        
        let transactionsHistoryRepo = self.reposController.getTransactionsHistoryRepo(for: balanceId)
        let sectionsProvider = TransactionDetails.OperationSectionsProvider(
            transactionsHistoryRepo: transactionsHistoryRepo,
            identifier: transactionId,
            accountId: self.userDataProvider.walletData.accountId
        )
        let vc = SharedSceneBuilder.createTransactionDetailsScene(
            sectionsProvider: sectionsProvider,
            routing: routing
        )
        
        vc.navigationItem.title = Localized(.transaction_details)
        
        return vc
    }
    
    private func runSendPaymentFlow(balanceId: String?) {
        let flow = SendPaymentFlowController(
            navigationController: self.navigationController,
            appController: self.appController,
            flowControllerStack: self.flowControllerStack,
            reposController: self.reposController,
            managersController: self.managersController,
            userDataProvider: self.userDataProvider,
            keychainDataProvider: self.keychainDataProvider,
            rootNavigation: self.rootNavigation,
            selectedBalanceId: balanceId
        )
        self.currentFlowController = flow
        flow.run(
            showRootScreen: { [weak self] (vc) in
                self?.navigationController.pushViewController(vc, animated: true)
        },
            onShowWalletScreen: { [weak self] in
                self?.currentFlowController = nil
                self?.navigationController.popViewController(true)
        })
    }
}
