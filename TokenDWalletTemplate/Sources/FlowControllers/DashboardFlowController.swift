import UIKit

class DashboardFlowController: BaseSignedInFlowController {
    
    // MARK: - Private
    
    private let navigationController: NavigationControllerProtocol =
        NavigationController()
    private weak var walletScene: UIViewController?
    private var operationCompletionScene: UIViewController {
        return self.walletScene ?? UIViewController()
    }
    
    // MARK: - Public
    
    public func run(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        self.showDashboardScreen(showRootScreen: showRootScreen)
    }
    
    // MARK: - Private
    
    private func goBackToWalletScene() {
        _ = self.navigationController.popToViewController(
            self.operationCompletionScene,
            animated: true
        )
    }
    
    private func showDashboardScreen(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        let viewController = DashboardScene.ViewController()
        
        let routing = DashboardScene.Routing()
        
        let previewMaxLength: Int = 3
        
        let decimalFormatter = DecimalFormatter()
        
        let pendingOffersPreviewFetcher = TransactionsListScene.PreviewTransactionsFetcher(
            transactionsFetcher: TransactionsListScene.PendingOffersFetcher(
                pendingOffersRepo: self.reposController.pendingOffersRepo,
                balancesRepo: self.reposController.balancesRepo,
                decimalFormatter: decimalFormatter,
                originalAccountId: self.userDataProvider.walletData.accountId
            ),
            previewMaxLength: previewMaxLength
        )
        
        let actionProvider = TransactionsListScene.ActionProvider(
            assetsRepo: self.reposController.assetsRepo,
            balancesRepo: self.reposController.balancesRepo
        )
        
        let viewConfig = TransactionsListScene.Model.ViewConfig(actionButtonIsHidden: true)
        
        let pendingOffersPreviewRouting = TransactionsListScene.Routing(
            onDidSelectItemWithIdentifier: { [weak self] (identifier, _) in
                self?.showPendingOfferDetailsScreen(offerId: identifier)
            },
            showSendPayment: { _ in },
            showWithdraw: { _ in },
            showDeposit: { _ in },
            showReceive: { }
        )
        
        let pendingOffersPreviewList = SharedSceneBuilder.createTransactionsListScene(
            transactionsFetcher: pendingOffersPreviewFetcher,
            actionProvider: actionProvider,
            emptyTitle: Localized(.no_pending_offers),
            viewConfig: viewConfig,
            routing: pendingOffersPreviewRouting
        )
        
        let paymentsPreviewFetcher = TransactionsListScene.PreviewTransactionsFetcher(
            transactionsFetcher: TransactionsListScene.PaymentsFetcher(
                reposController: self.reposController,
                originalAccountId: self.userDataProvider.walletData.accountId
            ),
            previewMaxLength: previewMaxLength
        )
        let paymentsPreviewRouting = TransactionsListScene.Routing(
            onDidSelectItemWithIdentifier: { [weak self] (identifier, balanceId) in
                self?.showTransactionDetailsScreen(transactionId: identifier, balanceId: balanceId)
            },
            showSendPayment: { _ in },
            showWithdraw: { _ in },
            showDeposit: { _ in },
            showReceive: { }
        )
        
        let paymentsPreviewList = SharedSceneBuilder.createTransactionsListScene(
            transactionsFetcher: paymentsPreviewFetcher,
            actionProvider: actionProvider,
            emptyTitle: Localized(.no_payments),
            viewConfig: viewConfig,
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
        viewController.navigationItem.title = Localized(.dashboard)
        
        self.navigationController.setViewControllers([viewController], animated: false)
        
        if let showRoot = showRootScreen {
            showRoot(self.navigationController.getViewController())
        } else {
            self.rootNavigation.setRootContent(self.navigationController, transition: .fade, animated: false)
        }
    }
    
    private func showPaymentsFor(selectedBalanceId: String) {
        let transactionsFetcher = TransactionsListScene.PaymentsFetcher(
            reposController: self.reposController,
            originalAccountId: self.userDataProvider.walletData.accountId
        )
        
        let actionProvider = TransactionsListScene.ActionProvider(
            assetsRepo: self.reposController.assetsRepo,
            balancesRepo: self.reposController.balancesRepo
        )
        
        let viewConfig = TransactionsListScene.Model.ViewConfig(actionButtonIsHidden: false)
        
        let navigationController = self.navigationController
        let transactionsRouting = TransactionsListScene.Routing (
            onDidSelectItemWithIdentifier: { [weak self] (identifier, balanceId) in
                self?.showTransactionDetailsScreen(transactionId: identifier, balanceId: balanceId)
            },
            showSendPayment: { [weak self] (balanceId) in
                self?.runSendPaymentFlow(
                    navigationController: navigationController,
                    balanceId: balanceId,
                    completion: { [weak self] in
                        self?.goBackToWalletScene()
                })
            },
            showWithdraw: { [weak self] (balanceId) in
                self?.runWithdrawFlow(
                    navigationController: navigationController,
                    balanceId: balanceId,
                    completion: { [weak self] in
                        self?.goBackToWalletScene()
                })
            },
            showDeposit: { [weak self] (asset) in
                self?.showDepositScreen(
                    navigationController: navigationController,
                    assetId: asset
                )
            },
            showReceive: { [weak self] in
                self?.showReceiveScene(navigationController: navigationController)
        })
        
        let balancesFetcher = BalancesFetcher(
            balancesRepo: self.reposController.balancesRepo
        )
        let headerRateProvider: BalanceHeaderWithPicker.RateProviderProtocol = RateProvider(
            assetPairsRepo: self.reposController.assetPairsRepo
        )
        
        let container = SharedSceneBuilder.createWalletScene(
            transactionsFetcher: transactionsFetcher,
            actionProvider: actionProvider,
            transactionsRouting: transactionsRouting,
            viewConfig: viewConfig,
            headerRateProvider: headerRateProvider,
            balancesFetcher: balancesFetcher,
            selectedBalanceId: selectedBalanceId
        )
        self.walletScene = container
        self.navigationController.pushViewController(container, animated: true)
    }
    
    private func showPendingOffers() {
        let decimalFormatter = DecimalFormatter()
        let transactionsFetcher = TransactionsListScene.PendingOffersFetcher(
            pendingOffersRepo: self.reposController.pendingOffersRepo,
            balancesRepo: self.reposController.balancesRepo,
            decimalFormatter: decimalFormatter,
            originalAccountId: self.userDataProvider.walletData.accountId
        )
        
        let actionProvider = TransactionsListScene.ActionProvider(
            assetsRepo: self.reposController.assetsRepo,
            balancesRepo: self.reposController.balancesRepo
        )
        
        let viewConfig = TransactionsListScene.Model.ViewConfig(actionButtonIsHidden: true)
        
        let transactionsListRouting = TransactionsListScene.Routing(
            onDidSelectItemWithIdentifier: { [weak self] (identifier, _) in
                self?.showPendingOfferDetailsScreen(offerId: identifier)
            },
            showSendPayment: { _ in },
            showWithdraw: { _ in },
            showDeposit: { _ in },
            showReceive: { }
        )
        
        let viewController = SharedSceneBuilder.createTransactionsListScene(
            transactionsFetcher: transactionsFetcher,
            actionProvider: actionProvider,
            emptyTitle: Localized(.no_pending_offers),
            viewConfig: viewConfig,
            routing: transactionsListRouting
        )
        
        viewController.navigationItem.title = Localized(.pending_offers)
        
        self.navigationController.pushViewController(viewController, animated: true)
    }
    
    private func showTransactionDetailsScreen(
        transactionId: UInt64,
        balanceId: String
        ) {
        
        let transactionsHistoryRepo = self.reposController.getTransactionsHistoryRepo(for: balanceId)
        let emailFetcher = TransactionDetails.EmailFetcher(
            generalApi: self.flowControllerStack.api.generalApi
        )
        let sectionsProvider = TransactionDetails.OperationSectionsProvider(
            transactionsHistoryRepo: transactionsHistoryRepo,
            emailFetcher: emailFetcher,
            identifier: transactionId,
            accountId: self.userDataProvider.walletData.accountId
        )
        let vc = self.setupTransactionDetailsScreen(
            sectionsProvider: sectionsProvider,
            title: Localized(.transaction_details)
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
            networkInfoFetcher: self.flowControllerStack.networkInfoFetcher,
            userDataProvider: self.userDataProvider,
            identifier: offerId
        )
        let vc = self.setupTransactionDetailsScreen(
            sectionsProvider: sectionsProvider,
            title: Localized(.pending_offer_details)
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
