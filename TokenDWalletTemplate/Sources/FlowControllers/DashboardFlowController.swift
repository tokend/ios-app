import UIKit

class DashboardFlowController: BaseSignedInFlowController {
    
    // MARK: - Private
    
    private let navigationController: NavigationControllerProtocol =
        NavigationController()
    
    // MARK: - Public
    
    public func run(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        self.showDashboardScreen(showRootScreen: showRootScreen)
    }
    
    // MARK: - Private
    
    private func showDashboardScreen(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        let viewController = DashboardScene.ViewController()
        
        let routing = DashboardScene.Routing()
        
        let previewMaxLength: Int = 3
        
        let previewRateProvider: TransactionsListScene.RateProviderProtocol = RateProvider(
            assetPairsRepo: self.reposController.assetPairsRepo
        )
        
        let pendingOffersPreviewFetcher = TransactionsListScene.PreviewTransactionsFetcher(
            transactionsFetcher: TransactionsListScene.PendingOffersFetcher(
                pendingOffersRepo: self.reposController.pendingOffersRepo,
                balancesRepo: self.reposController.balancesRepo,
                rateProvider: previewRateProvider,
                originalAccountId: self.userDataProvider.walletData.accountId
            ),
            previewMaxLength: previewMaxLength
        )
        let pendingOffersPreviewRouting = TransactionsListScene.Routing(
            onDidSelectItemWithIdentifier: { [weak self] (identifier, _) in
                self?.showPendingOfferDetailsScreen(offerId: identifier)
            }
        )
        let pendingOffersPreviewList = SharedSceneBuilder.createTransactionsListScene(
            transactionsFetcher: pendingOffersPreviewFetcher,
            emptyTitle: "No pending offers",
            routing: pendingOffersPreviewRouting
        )
        
        let paymentsPreviewFetcher = TransactionsListScene.PreviewTransactionsFetcher(
            transactionsFetcher: TransactionsListScene.PaymentsFetcher(
                reposController: self.reposController,
                rateProvider: previewRateProvider,
                originalAccountId: self.userDataProvider.walletData.accountId
            ),
            previewMaxLength: previewMaxLength
        )
        let paymentsPreviewRouting = TransactionsListScene.Routing(
            onDidSelectItemWithIdentifier: { [weak self] (identifier, asset) in
                self?.showTransactionDetailsScreen(transactionId: identifier, asset: asset)
            }
        )
        let paymentsPreviewList = SharedSceneBuilder.createTransactionsListScene(
            transactionsFetcher: paymentsPreviewFetcher,
            emptyTitle: "No payments",
            routing: paymentsPreviewRouting
        )
        
        let paymentsPreviewPlugIn = DashboardPaymentsPlugIn.ViewController()
        let paymentsPreviewPlugInAmountFormatter = DashboardPaymentsPlugIn.AmountFormatter()
        let paymentsPreviewPlugInRateProvider: DashboardPaymentsPlugIn.RateProviderProtocol = RateProvider(
            assetPairsRepo: self.reposController.assetPairsRepo
        )
        let paymentsPreviewPlugInRouting = DashboardPaymentsPlugIn.Routing(
            onViewMoreAction: { [weak self] (balanceId) in
                self?.showPaymentsFor(selectedBalanceId: balanceId)
        })
        let paymentsPreviewBalancesFetcher: DashboardPaymentsPlugIn.BalancesFetcherProtocol = BalancesFetcher(
            balancesRepo: self.reposController.balancesRepo
        )
        
        let pendingOffersPreviewPlugIn = DashboardPendingOffersPreviewPlugIn.ViewController()
        let pendingOffersPreviewPlugInRouting = DashboardPendingOffersPreviewPlugIn.Routing(
            onViewMoreAction: { [weak self] in
                self?.showPendingOffers()
        })
        DashboardPendingOffersPreviewPlugIn.Configurator.configure(
            viewController: pendingOffersPreviewPlugIn,
            routing: pendingOffersPreviewPlugInRouting
        )
        
        DashboardPaymentsPlugIn.Configurator.configure(
            viewController: paymentsPreviewPlugIn,
            amountFormatter: paymentsPreviewPlugInAmountFormatter,
            balancesFetcher: paymentsPreviewBalancesFetcher,
            rateProvider: paymentsPreviewPlugInRateProvider,
            routing: paymentsPreviewPlugInRouting
        )
        paymentsPreviewPlugIn.transactionsList = paymentsPreviewList
        pendingOffersPreviewPlugIn.transactionsList = pendingOffersPreviewList
        
        let plugInsProvider = DashboardScene.PlugInsProvider(
            plugIns: [
                paymentsPreviewPlugIn,
                pendingOffersPreviewPlugIn
            ]
        )
        
        DashboardScene.Configurator.configure(
            viewController: viewController,
            plugInsProvider: plugInsProvider,
            routing: routing
        )
        viewController.navigationItem.title = "Dashboard"
        
        self.navigationController.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: Theme.Fonts.navigationBarBoldFont,
            NSAttributedString.Key.foregroundColor: Theme.Colors.textOnMainColor
        ]
        self.navigationController.navigationBar.shadowImage = UIImage()
        
        self.navigationController.setViewControllers([viewController], animated: false)
        
        if let showRoot = showRootScreen {
            showRoot(self.navigationController.getViewController())
        } else {
            self.rootNavigation.setRootContent(self.navigationController, transition: .fade, animated: false)
        }
    }
    
    private func showPaymentsFor(selectedBalanceId: String) {
        let transactionsListRateProvider: TransactionsListScene.RateProviderProtocol = RateProvider(
            assetPairsRepo: self.reposController.assetPairsRepo
        )
        let transactionsFetcher = TransactionsListScene.PaymentsFetcher(
            reposController: self.reposController,
            rateProvider: transactionsListRateProvider,
            originalAccountId: self.userDataProvider.walletData.accountId
        )
        
        let transactionsRouting = TransactionsListScene.Routing(
            onDidSelectItemWithIdentifier: { [weak self] (transactionId, asset) in
                self?.showTransactionDetailsScreen(transactionId: transactionId, asset: asset)
        })
        
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
            balancesFetcher: balancesFetcher,
            selectedBalanceId: selectedBalanceId
        )
        
        self.navigationController.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: Theme.Fonts.navigationBarBoldFont,
            NSAttributedString.Key.foregroundColor: Theme.Colors.textOnMainColor
        ]
        self.navigationController.navigationBar.shadowImage = UIImage()
        
        self.navigationController.pushViewController(container, animated: true)
    }
    
    private func showPendingOffers() {
        let transactionsListRateProvider: TransactionsListScene.RateProviderProtocol = RateProvider(
            assetPairsRepo: self.reposController.assetPairsRepo
        )
        let transactionsFetcher = TransactionsListScene.PendingOffersFetcher(
            pendingOffersRepo: self.reposController.pendingOffersRepo,
            balancesRepo: self.reposController.balancesRepo,
            rateProvider: transactionsListRateProvider,
            originalAccountId: self.userDataProvider.walletData.accountId
        )
        
        let transactionsListRouting = TransactionsListScene.Routing(
            onDidSelectItemWithIdentifier: { [weak self] (identifier, _) in
                self?.showPendingOfferDetailsScreen(offerId: identifier)
        })
        
        let viewController = SharedSceneBuilder.createTransactionsListScene(
            transactionsFetcher: transactionsFetcher,
            emptyTitle: "No pending offers",
            routing: transactionsListRouting
        )
        
        self.navigationController.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: Theme.Fonts.navigationBarBoldFont,
            NSAttributedString.Key.foregroundColor: Theme.Colors.textOnMainColor
        ]
        self.navigationController.navigationBar.shadowImage = UIImage()
        
        viewController.navigationItem.title = "Pending offers"
        
        self.navigationController.pushViewController(viewController, animated: true)
    }
    
    private func showTransactionDetailsScreen(
        transactionId: UInt64,
        asset: String
        ) {
        let sectionsProvider = TransactionDetails.OperationSectionsProvider(
            transactionsRepo: self.reposController.transactionsRepoForAsset(asset),
            identifier: transactionId,
            accountId: self.userDataProvider.walletData.accountId
        )
        let vc = self.setupTransactionDetailsScreen(
            sectionsProvider: sectionsProvider,
            title: "Transaction details"
        )
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func showPendingOfferDetailsScreen(
        offerId: UInt64
        ) {
        let sectionsProvider = TransactionDetails.PendingOfferSectionsProvider(
            pendingOffersRepo: self.reposController.pendingOffersRepo,
            transactionSender: self.managersController.transactionSender,
            amountConverter: AmountConverter(),
            amountPrecision: self.flowControllerStack.apiConfigurationModel.amountPrecision,
            networkInfoFetcher: self.flowControllerStack.networkInfoFetcher,
            userDataProvider: self.userDataProvider,
            identifier: offerId
        )
        let vc = self.setupTransactionDetailsScreen(
            sectionsProvider: sectionsProvider,
            title: "Pending offer details"
        )
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupTransactionDetailsScreen(
        sectionsProvider: TransactionDetails.SectionsProviderProtocol,
        title: String
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
        
        let vc = SharedSceneBuilder.createTransactionDetailsScene(
            sectionsProvider: sectionsProvider,
            routing: routing
        )
        
        vc.navigationItem.title = title
        
        return vc
    }
}
