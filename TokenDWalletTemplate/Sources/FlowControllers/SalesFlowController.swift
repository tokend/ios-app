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
        let chartTab = self.setupSaleChartTabModel(saleIdentifier: identifier)
        let detailsTab = self.setupSaleDetailsTabModel(identifier: identifier, asset: asset)
        
        let tabs: [TabsContainer.Model.TabModel] = [
            overviewTab,
            chartTab,
            detailsTab
        ]
        
        let contentProvider = TabsContainer.InfoContentProvider(tabs: tabs)
        let viewConfig = TabsContainer.Model.ViewConfig(
            isPickerHidden: false,
            isTabBarHidden: true,
            actionButtonAppearence: .visible(title: Localized(.invest))
        )
        
        let routing = TabsContainer.Routing(onAction: { [weak self] in
            self?.showSaleInvestmentScene(saleIdentifier: identifier)
        })
        
        TabsContainer.Configurator.configure(
            viewController: vc,
            contentProvider: contentProvider,
            viewConfig: viewConfig,
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
    
    private func setupSaleChartTabModel(saleIdentifier: String) -> TabsContainer.Model.TabModel {
        let vc = Chart.ViewController()
        
        let sceneModel = Chart.Model.SceneModel()
        let dataProvider = Chart.DataProvider(
            saleIdentifier: saleIdentifier,
            salesRepo: self.reposController.salesRepo,
            chartsApi: self.flowControllerStack.api.chartsApi
        )
        let amountFormatter = Chart.AmountFormatter()
        let dateFormatter = Chart.DateFormatter()
        let chartDateFormatter = Chart.ChartDateFormatter()
        
        let routing = Chart.Routing()
        
        Chart.Configurator.configure(
            viewController: vc,
            sceneModel: sceneModel,
            dataProvider: dataProvider,
            amountFormatter: amountFormatter,
            dateFormatter: dateFormatter,
            chartDateFormatter: chartDateFormatter,
            routing: routing
        )
        
        let tab = TabsContainer.Model.TabModel(
            title: Localized(.chart),
            content: .viewController(vc),
            identifier: Localized(.chart)
        )
        
        return tab
    }
    
    private func showSaleInvestmentScene(saleIdentifier: String) {
        let vc = self.setupSaleInvestmentScene(saleIdentifier: saleIdentifier)
        
        vc.navigationItem.title = Localized(.investment)
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupSaleInvestmentScene(saleIdentifier: String) -> UIViewController {
        let vc = SaleInvest.ViewController()
        
        let investedAmountFormatter = SaleInvest.InvestAmountFormatter()
        let amountFormatter = SaleInvest.AmountFormatter()
        let dataProvider = SaleInvest.SaleInvestProvider(
            saleIdentifier: saleIdentifier,
            salesRepo: self.reposController.salesRepo,
            assetsRepo: reposController.assetsRepo,
            balancesRepo: reposController.balancesRepo,
            walletRepo: reposController.walletRepo,
            offersRepo: reposController.pendingOffersRepo
        )
        
        let amountConverter = AmountConverter()
        let cancelInvestWorker = SaleInvest.CancelInvestWorker(
            transactionSender: self.managersController.transactionSender,
            amountConverter: amountConverter,
            networkInfoFetcher: self.reposController.networkInfoRepo,
            userDataProvider: self.userDataProvider
        )
        let feeLoader = FeeLoader(generalApi: self.flowControllerStack.api.generalApi)
        let sceneModel = SaleInvest.Model.SceneModel(
            investorAccountId: self.userDataProvider.walletData.accountId,
            inputAmount: 0.0,
            selectedBalance: nil
        )
        
        let routing = SaleInvest.Routing(
            onShowProgress: { [weak self] in
                self?.navigationController.showProgress()
            },
            onHideProgress: { [weak self] in
                self?.navigationController.hideProgress()
            },
            onShowError: { [weak self] (message) in
                self?.navigationController.showErrorMessage(message, completion: nil)
            },
            onPresentPicker: { [weak self] (title, options, onSelected) in
                guard let presenter = self?.navigationController.getPresentViewControllerClosure() else {
                    return
                }
                self?.showDialog(
                    title: title,
                    message: nil,
                    style: .actionSheet,
                    options: options,
                    onSelected: onSelected,
                    onCanceled: nil,
                    presentViewController: presenter
                )
            },
            showDialog: { [weak self] (title, message, options, onSelected) in
                guard let presenter = self?.navigationController.getPresentViewControllerClosure() else {
                    return
                }
                self?.showDialog(
                    title: title,
                    message: message,
                    style: .alert,
                    options: options,
                    onSelected: onSelected,
                    onCanceled: nil,
                    presentViewController: presenter
                )
            },
            onSaleInvestAction: { [weak self] (saleInvestModel) in
                self?.showSaleInvestConfirmationScreen(saleInvestModel: saleInvestModel)
            }
        )
        
        SaleInvest.Configurator.configure(
            viewController: vc,
            investedAmountFormatter: investedAmountFormatter,
            amountFormatter: amountFormatter,
            dataProvider: dataProvider,
            cancelInvestWorker: cancelInvestWorker,
            feeLoader: feeLoader,
            sceneModel: sceneModel,
            routing: routing
        )
        
        return vc
    }
    
    private func showSaleInvestConfirmationScreen(saleInvestModel: SaleInvest.Model.SaleInvestModel) {
        let vc = self.setupSaleInvestConfirmationScreen(saleInvestModel: saleInvestModel)
        
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupSaleInvestConfirmationScreen(
        saleInvestModel: SaleInvest.Model.SaleInvestModel
        ) -> ConfirmationScene.ViewController {
        
        let vc = ConfirmationScene.ViewController()
        
        let amountFormatter = ConfirmationScene.AmountFormatter()
        let percentFormatter = ConfirmationScene.PercentFormatter()
        let amountConverter = AmountConverter()
        
        let saleInvestModel = ConfirmationScene.Model.SaleInvestModel(
            baseAsset: saleInvestModel.baseAsset,
            quoteAsset: saleInvestModel.quoteAsset,
            baseBalance: saleInvestModel.baseBalance,
            quoteBalance: saleInvestModel.quoteBalance,
            isBuy: saleInvestModel.isBuy,
            baseAmount: saleInvestModel.baseAmount,
            quoteAmount: saleInvestModel.quoteAmount,
            baseAssetName: saleInvestModel.baseAssetName,
            price: saleInvestModel.price,
            fee: saleInvestModel.fee,
            type: saleInvestModel.type,
            offerId: saleInvestModel.offerId,
            prevOfferId: saleInvestModel.prevOfferId,
            orderBookId: saleInvestModel.orderBookId
        )
        
        let sectionsProvider = ConfirmationScene.SaleInvestConfirmationProvider(
            saleInvestModel: saleInvestModel,
            transactionSender: self.managersController.transactionSender,
            networkInfoFetcher: self.reposController.networkInfoRepo,
            amountFormatter: amountFormatter,
            userDataProvider: self.userDataProvider,
            amountConverter: amountConverter,
            percentFormatter: percentFormatter
        )
        
        let routing = ConfirmationScene.Routing(
            onShowProgress: { [weak self] in
                self?.navigationController.showProgress()
            },
            onHideProgress: { [weak self] in
                self?.navigationController.hideProgress()
            },
            onShowError: { [weak self] (errorMessage) in
                self?.navigationController.showErrorMessage(errorMessage, completion: nil)
            },
            onConfirmationSucceeded: { [weak self] in
                self?.onShowWalletScreen?(saleInvestModel.quoteBalance)
        })
        
        ConfirmationScene.Configurator.configure(
            viewController: vc,
            sectionsProvider: sectionsProvider,
            routing: routing
        )
        
        vc.navigationItem.title = Localized(.confirmation)
        
        return vc
    }
}
