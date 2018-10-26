import UIKit

class WalletDetailsFlowController: BaseSignedInFlowController {
    
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
        let transactionsRouting = TransactionsListScene.Routing { [weak self] (identifier, asset) in
            self?.showTransactionDetailsScreen(transactionId: identifier, asset: asset)
        }
        
        let balancesFetcher = BalancesFetcher(
            balancesRepo: self.reposController.balancesRepo
        )
        let headerRateProvider: BalanceHeaderWithPicker.RateProviderProtocol = RateProvider(
            assetPairsRepo: self.reposController.assetPairsRepo
        )
        
        let container = SharedSceneBuilder.createWalletScene(
            transactionsFetcher: transactionsFetcher,
            transactionsRouting: transactionsRouting,
            headerRateProvider: headerRateProvider,
            balancesFetcher: balancesFetcher
        )
        
        self.navigationController.navigationBar.titleTextAttributes = [
            NSAttributedStringKey.font: Theme.Fonts.navigationBarBoldFont,
            NSAttributedStringKey.foregroundColor: Theme.Colors.textOnMainColor
        ]
        self.navigationController.navigationBar.shadowImage = UIImage()
        
        self.navigationController.setViewControllers([container], animated: false)
        
        if let showRoot = showRootScreen {
            showRoot(self.navigationController.getViewController())
        } else {
            self.rootNavigation.setRootContent(self.navigationController, transition: .fade, animated: false)
        }
    }
    
    private func showTransactionDetailsScreen(
        transactionId: UInt64,
        asset: String
        ) {
        let vc = self.setupTransactionDetailsScreen(
            transactionId: transactionId,
            asset: asset
        )
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupTransactionDetailsScreen(
        transactionId: UInt64,
        asset: String
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
        let sectionsProvider = TransactionDetails.OperationSectionsProvider(
            transactionsRepo: self.reposController.transactionsRepoForAsset(asset),
            identifier: transactionId,
            accountId: self.userDataProvider.walletData.accountId
        )
        let vc = SharedSceneBuilder.createTransactionDetailsScene(
            sectionsProvider: sectionsProvider,
            routing: routing
        )
        
        vc.navigationItem.title = "Transaction details"
        
        return vc
    }
}
