import UIKit
import TokenDSDK

class SalesFlowController: BaseSignedInFlowController {
    
    // MARK: - Private properties
    
    private let navigationController: NavigationControllerProtocol = NavigationController()
    
    private var onShowWalletScreen: ((_ selectedBalanceId: String?) -> Void)?
    
    // MARK: - Public
    
    public func run(
        showRootScreen: ((_ vc: UIViewController) -> Void)?,
        onShowWalletScreen: @escaping (_ selectedBalanceId: String?) -> Void
        ) {
        
        self.onShowWalletScreen = onShowWalletScreen
        self.showSalesScreen(showRootScreen: showRootScreen)
    }
    
    // MARK: - Private
    
    private func showSalesScreen(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        let vc = self.setupSalesScreen()
        
        self.navigationController.setViewControllers([vc], animated: false)
        
        if let showRoot = showRootScreen {
            showRoot(self.navigationController.getViewController())
        } else {
            self.rootNavigation.setRootContent(
                self.navigationController,
                transition: .fade,
                animated: false
            )
        }
    }
    
    private func setupSalesScreen() -> Sales.ViewController {
        let vc = Sales.ViewController()
        
        let routing = Sales.Routing(
            onDidSelectSale: { [weak self] (identifier, asset) in
                self?.showSaleInfoScreen(identifier: identifier, asset: asset)
            },
            onShowInvestments: { [weak self] in
                self?.showInvestments()
            },
            onShowLoading: { [weak self] in
                self?.navigationController.showProgress()
            },
            onHideLoading: { [weak self] in
                self?.navigationController.hideProgress()
        })
        
        let sectionsProvider = Sales.SalesSectionsProvider(
            salesRepo: self.reposController.salesRepo,
            imagesUtility: self.reposController.imagesUtility
        )
        
        let investedAmountFormatter = Sales.AmountFormatter()
        
        Sales.Configurator.configure(
            viewController: vc,
            sectionsProvider: sectionsProvider,
            investedAmountFormatter: investedAmountFormatter,
            routing: routing
        )
        
        vc.navigationItem.title = Localized(.sales)
        
        return vc
    }
    
    private func showInvestments() {
        let transactionsListRateProvider: TransactionsListScene.RateProviderProtocol = RateProvider(
            assetPairsRepo: self.reposController.assetPairsRepo
        )
        let transactionsFetcher = TransactionsListScene.SalesFetcher(
            pendingOffersRepo: self.reposController.pendingOffersRepo,
            balancesRepo: self.reposController.balancesRepo,
            rateProvider: transactionsListRateProvider,
            originalAccountId: self.userDataProvider.walletData.accountId
        )
        
        let actionProvider = TransactionsListScene.ActionProvider(
            assetsRepo: self.reposController.assetsRepo,
            balancesRepo: self.reposController.balancesRepo
        )
        
        let transactionsListRouting = TransactionsListScene.Routing(
            onDidSelectItemWithIdentifier: { [weak self] (identifier, _) in
                guard let navigationController = self?.navigationController else { return }
                self?.showInvestmentDetailsScreen(
                    offerId: identifier,
                    navigationController: navigationController
                )
            },
            showSendPayment: { _ in },
            showWithdraw: { _ in },
            showDeposit: { _ in },
            showReceive: { }
        )
        
        let viewConfig = TransactionsListScene.Model.ViewConfig(actionButtonIsHidden: true)
        
        let vc = SharedSceneBuilder.createTransactionsListScene(
            transactionsFetcher: transactionsFetcher,
            actionProvider: actionProvider,
            emptyTitle: Localized(.no_investments),
            viewConfig: viewConfig,
            routing: transactionsListRouting
        )
        
        vc.navigationItem.title = Localized(.investments)
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func showInvestmentDetailsScreen(
        offerId: UInt64,
        navigationController: NavigationControllerProtocol
        ) {
        
        let sectionsProvider = TransactionDetails.InvestmentSectionsProvider(
            pendingOffersRepo: self.reposController.pendingOffersRepo,
            transactionSender: self.managersController.transactionSender,
            amountConverter: AmountConverter(),
            networkInfoFetcher: self.flowControllerStack.networkInfoFetcher,
            userDataProvider: self.userDataProvider,
            identifier: offerId
        )
        
        let vc = self.setupTransactionDetailsScreen(
            navigationController: navigationController,
            sectionsProvider: sectionsProvider,
            title: Localized(.investment_details)
        )
        
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func showSaleInfoScreen(identifier: String, asset: String) {
        let vc = self.setupSaleInfoScreen(identifier: identifier, asset: asset)
        
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupSaleInfoScreen(identifier: String, asset: String) -> TabsContainer.ViewController {
        let vc = TabsContainer.ViewController()
        
        let overviewTab = self.setupSaleOverviewTabModel(identifier: identifier)
//        let detailsTab = self.setupSaleDetailsTabModel(identifier: identifier, asset: asset)
        
        let tabs: [TabsContainer.Model.TabModel] = [
            overviewTab
//            detailsTab
        ]
        
        let contentProvider = TabsContainer.InfoContentProvider(tabs: tabs)
        
        let routing = TabsContainer.Routing()
        
        TabsContainer.Configurator.configure(
            viewController: vc,
            contentProvider: contentProvider,
            routing: routing
        )
        
        vc.navigationItem.title = Localized(.sale_details)
        
        return vc
    }
    
    private func setupSaleOverviewTabModel(identifier: String) -> TabsContainer.Model.TabModel {
        let vc = SaleOverview.ViewController()
        
        let dataProvider = SaleOverview.OverviewDataProvider(
            saleIdentifier: identifier,
            salesRepo: self.reposController.salesRepo,
            blobsApi: self.flowControllerStack.api.blobsApi,
            imagesUtility: self.reposController.imagesUtility
        )
        
        let investedAmountFormatter = SaleOverview.InvestAmountFormatter()
        
        let routing = SaleOverview.Routing()
        
        SaleOverview.Configurator.configure(
            viewController: vc,
            dataProvider: dataProvider,
            investedAmountFormatter: investedAmountFormatter,
            routing: routing
        )
        
        let tab = TabsContainer.Model.TabModel(
            title: Localized(.overview),
            content: .viewController(vc),
            identifier: Localized(.overview)
        )
        
        return tab
    }
    
    private func setupSaleDetailsTabModel(
        identifier: String,
        asset: String
        ) -> TabsContainer.Model.TabModel {
        
        let vc = SaleDetails.ViewController()
        
        let dataProvider = SaleDetails.SaleDetailsDataProvider(
            accountId: self.userDataProvider.walletData.accountId,
            saleId: identifier,
            asset: asset,
            salesApi: self.flowControllerStack.api.salesApi,
            assetsRepo: self.reposController.assetsRepo,
            imagesUtility: self.reposController.imagesUtility,
            balancesRepo: self.reposController.balancesRepo
        )
        let dateFormatter = SaleDetails.DateFormatter()
        let amountFormatter = SaleDetails.AmountFormatter()
        
        let routing = SaleDetails.Routing()
        
        SaleDetails.Configurator.configure(
            viewController: vc,
            dataProvider: dataProvider,
            dateFormatter: dateFormatter,
            amountFormatter: amountFormatter,
            routing: routing
        )
        
        let tab = TabsContainer.Model.TabModel(
            title: Localized(.details),
            content: .viewController(vc),
            identifier: Localized(.details)
        )
        
        return tab
    }
    
//    private func showSaleInvestConfirmationScreen(saleInvestModel: SaleDetails.Model.SaleInvestModel1) {
//        let vc = self.setupSaleInvestConfirmationScreen(saleInvestModel: saleInvestModel)
//
//        self.navigationController.pushViewController(vc, animated: true)
//    }
//
//    private func setupSaleInvestConfirmationScreen(
//        saleInvestModel: SaleDetails.Model.SaleInvestModel1
//        ) -> ConfirmationScene.ViewController {
//
//        let vc = ConfirmationScene.ViewController()
//
//        let amountFormatter = ConfirmationScene.AmountFormatter()
//        let percentFormatter = ConfirmationScene.PercentFormatter()
//        let amountConverter = AmountConverter()
//
//        let saleInvestModel = ConfirmationScene.Model.SaleInvestModel(
//            baseAsset: saleInvestModel.baseAsset,
//            quoteAsset: saleInvestModel.quoteAsset,
//            baseBalance: saleInvestModel.baseBalance,
//            quoteBalance: saleInvestModel.quoteBalance,
//            isBuy: saleInvestModel.isBuy,
//            baseAmount: saleInvestModel.baseAmount,
//            quoteAmount: saleInvestModel.quoteAmount,
//            baseAssetName: saleInvestModel.baseAssetName,
//            price: saleInvestModel.price,
//            fee: saleInvestModel.fee,
//            type: saleInvestModel.type,
//            offerId: saleInvestModel.offerId,
//            prevOfferId: saleInvestModel.prevOfferId,
//            orderBookId: saleInvestModel.orderBookId
//        )
//
//        let sectionsProvider = ConfirmationScene.SaleInvestConfirmationProvider(
//            saleInvestModel: saleInvestModel,
//            transactionSender: self.managersController.transactionSender,
//            networkInfoFetcher: self.reposController.networkInfoRepo,
//            amountFormatter: amountFormatter,
//            userDataProvider: self.userDataProvider,
//            amountConverter: amountConverter,
//            percentFormatter: percentFormatter
//        )
//
//        let routing = ConfirmationScene.Routing(
//            onShowProgress: { [weak self] in
//                self?.navigationController.showProgress()
//            },
//            onHideProgress: { [weak self] in
//                self?.navigationController.hideProgress()
//            },
//            onShowError: { [weak self] (errorMessage) in
//                self?.navigationController.showErrorMessage(errorMessage, completion: nil)
//            },
//            onConfirmationSucceeded: { [weak self] in
//                self?.onShowWalletScreen?(saleInvestModel.quoteBalance)
//        })
//
//        ConfirmationScene.Configurator.configure(
//            viewController: vc,
//            sectionsProvider: sectionsProvider,
//            routing: routing
//        )
//
//        vc.navigationItem.title = Localized(.confirmation)
//
//        return vc
//    }
    
//    private func showSaleInfoScreen(saleInfoModel: SaleDetails.Model.SaleInfoModel1) {
//        let vc = self.setupSaleInfoScene(saleInfoModel: saleInfoModel)
//
//        self.navigationController.pushViewController(vc, animated: true)
//    }
//
//    private func setupSaleInfoScene(saleInfoModel: SaleDetails.Model.SaleInfoModel1) -> SaleInfo.ViewController {
//        let vc = SaleInfo.ViewController()
//        let dataProvider = SaleInfo.SaleInfoDataProvider(
//            accountId: self.userDataProvider.walletData.accountId,
//            saleId: saleInfoModel.saleId,
//            asset: saleInfoModel.asset,
//            salesApi: self.flowControllerStack.api.salesApi,
//            assetsRepo: self.reposController.assetsRepo,
//            imagesUtility: self.reposController.imagesUtility,
//            balancesRepo: self.reposController.balancesRepo
//        )
//
//        let routing  = SaleInfo.Routing()
//        let sceneModel = SaleInfo.Model.SceneModel(tabs: [])
//        let dateFormatter = SaleInfo.DateFormatter()
//        let amountFormatter = SaleInfo.AmountFormatter()
//
//        SaleInfo.Configurator.configure(
//            viewController: vc,
//            sceneModel: sceneModel,
//            dataProvider: dataProvider,
//            dateFormatter: dateFormatter,
//            amountFormatter: amountFormatter,
//            routing: routing
//        )
//        return vc
//    }
}
