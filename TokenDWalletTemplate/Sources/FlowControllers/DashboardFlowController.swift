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
        
        let transactionsRouting = TransactionsListScene.Routing(
            onDidSelectItemWithIdentifier: { [weak self] (transactionId, balanceId) in
                self?.showTransactionDetailsScreen(transactionId: transactionId, balanceId: balanceId)
            },
            showSendPayment: { [weak self] (balanceId) in
                self?.runSendPaymentFlow(balanceId: balanceId)
            },
            showWithdraw: { [weak self] (balanceId) in
                self?.runWithdrawFlow(balanceId: balanceId)
            },
            showDeposit: { [weak self] (assetId) in
                self?.showDepositScreen(assetId: assetId)
            },
            showReceive: { [weak self] in
                self?.showReceiveScene()
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
                self?.goBackToWalletScene()
        })
    }
    
    private func showReceiveScene() {
        let vc = ReceiveAddress.ViewController()
        
        let viewConfig = ReceiveAddress.Model.ViewConfig(
            copiedLocalizationKey: Localized(.copied),
            tableViewTopInset: 24
        )
        
        let addressManager = ReceiveAddress.ReceiveAddressManager(
            accountId: self.userDataProvider.walletData.accountId
        )
        
        let sceneModel = ReceiveAddress.Model.SceneModel()
        
        let qrCodeGenerator = QRCodeGenerator()
        let shareUtil = ReceiveAddress.ReceiveAddressShareUtil(
            qrCodeGenerator: qrCodeGenerator
        )
        
        let invoiceFormatter = ReceiveAddress.InvoiceFormatter()
        
        let routing = ReceiveAddress.Routing(
            onCopy: { (stringToCopy) in
                UIPasteboard.general.string = stringToCopy
        },
            onShare: { [weak self] (itemsToShare) in
                self?.shareItems(itemsToShare)
        })
        
        ReceiveAddress.Configurator.configure(
            viewController: vc,
            viewConfig: viewConfig,
            sceneModel: sceneModel,
            addressManager: addressManager,
            shareUtil: shareUtil,
            qrCodeGenerator: qrCodeGenerator,
            invoiceFormatter: invoiceFormatter,
            routing: routing
        )
        
        vc.navigationItem.title = Localized(.receive)
        
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func runWithdrawFlow(balanceId: String?) {
        let flow = WithdrawFlowController(
            appController: self.appController,
            flowControllerStack: self.flowControllerStack,
            reposController: self.reposController,
            managersController: self.managersController,
            userDataProvider: self.userDataProvider,
            keychainDataProvider: self.keychainDataProvider,
            rootNavigation: self.rootNavigation,
            navigationController: self.navigationController,
            selectedBalanceId: balanceId
        )
        self.currentFlowController = flow
        flow.run(
            showRootScreen: { [weak self] (vc) in
                self?.navigationController.pushViewController(vc, animated: true)
            },
            onShowWalletScreen: { [weak self] in
                self?.currentFlowController = nil
                self?.goBackToWalletScene()
        })
    }
    
    private func showDepositScreen(assetId: String?) {
        let viewController = DepositScene.ViewController()
        
        let sceneModel = DepositScene.Model.SceneModel(
            selectedAssetId: assetId ?? "",
            assets: [],
            qrCodeSize: .zero
        )
        
        let qrCodeGenerator = QRCodeGenerator()
        let dateFormatter = DepositScene.DateFormatter()
        let assetsFetcher = DepositScene.AssetsFetcher(
            assetsRepo: self.reposController.assetsRepo,
            balancesRepo: self.reposController.balancesRepo,
            accountRepo: self.reposController.accountRepo,
            externalSystemBalancesManager: self.managersController.externalSystemBalancesManager
        )
        let balanceBinder = BalanceBinder(
            balancesRepo: self.reposController.balancesRepo,
            accountRepo: self.reposController.accountRepo,
            externalSystemBalancesManager: self.managersController.externalSystemBalancesManager
        )
        let addressManager = DepositScene.AddressManager(
            balanceBinder: balanceBinder
        )
        
        let errorFormatter = DepositScene.ErrorFormatter()
        
        let routing = DepositScene.Routing(
            onShare: { [weak self] (items) in
                self?.shareItems(items)
            },
            onError: { [weak self] (message) in
                self?.navigationController.showErrorMessage(message, completion: nil)
        })
        
        DepositScene.Configurator.configure(
            viewController: viewController,
            sceneModel: sceneModel,
            qrCodeGenerator: qrCodeGenerator,
            dateFormatter: dateFormatter,
            assetsFetcher: assetsFetcher,
            addressManager: addressManager,
            errorFormatter: errorFormatter,
            routing: routing
        )
        
        viewController.navigationItem.title = Localized(.deposit)
        
        self.navigationController.pushViewController(viewController, animated: true)
    }
    
    private func shareItems(_ items: [Any]) {
        let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
        self.navigationController.present(activity, animated: true, completion: nil)
    }
}
