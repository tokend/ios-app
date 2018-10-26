import UIKit
import TokenDSDK

class SalesFlowController: BaseSignedInFlowController {
    
    // MARK: - Private properties
    
    private let navigationController: NavigationControllerProtocol = NavigationController()
    
    private var onShowWalletScreen: (() -> Void)?
    
    // MARK: - Public
    
    public func run(
        showRootScreen: ((_ vc: UIViewController) -> Void)?,
        onShowWalletScreen: @escaping () -> Void
        ) {
        
        self.onShowWalletScreen = onShowWalletScreen
        self.showSalesScreen(showRootScreen: showRootScreen)
    }
    
    // MARK: - Private
    
    private func showSalesScreen(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        let vc = self.setupSalesScreen()
        
        self.navigationController.navigationBar.titleTextAttributes = [
            NSAttributedStringKey.font: Theme.Fonts.navigationBarBoldFont,
            NSAttributedStringKey.foregroundColor: Theme.Colors.textOnMainColor
        ]
        self.navigationController.navigationBar.shadowImage = UIImage()
        
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
            onDidSelectSale: { [weak self] (identifier) in
                self?.showSaleDetailsScreen(identifier: identifier)
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
        
        vc.navigationItem.title = "Explore Funds"
        
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
        
        let transactionsListRouting = TransactionsListScene.Routing { [weak self] (identifier, _) in
            guard let strongSelf = self else { return }
            guard let navigationController = strongSelf.navigationController as? NavigationController else { return }
            strongSelf.showInvestmentDetailsScreen(
                offerId: identifier,
                navigationController: navigationController
            )
        }
        
        let vc = SharedSceneBuilder.createTransactionsListScene(
            transactionsFetcher: transactionsFetcher,
            emptyTitle: "No investments",
            routing: transactionsListRouting
        )
        
        vc.navigationItem.title = "Investments"
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func showInvestmentDetailsScreen(
        offerId: UInt64,
        navigationController: NavigationController
        ) {
        
        let vc = self.setupInvestmentDetailsScreen(
            offerId: offerId,
            navigationController: navigationController
        )
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupInvestmentDetailsScreen(
        offerId: UInt64,
        navigationController: NavigationController
        ) -> TransactionDetails.ViewController {
        
        let routing = TransactionDetails.Routing(
            successAction: {
                navigationController.popViewController(animated: true)
        },
            showProgress: {
                navigationController.showProgress()
        },
            hideProgress: {
                navigationController.hideProgress()
        },
            showError: { (error) in
                navigationController.showErrorMessage(error, completion: nil)
        })
        let sectionsProvider = TransactionDetails.InvestmentSectionsProvider(
            pendingOffersRepo: self.reposController.pendingOffersRepo,
            transactionSender: self.managersController.transactionSender,
            amountConverter: AmountConverter(),
            amountPrecision: self.flowControllerStack.apiConfigurationModel.amountPrecision,
            networkInfoFetcher: self.flowControllerStack.networkInfoFetcher,
            userDataProvider: self.userDataProvider,
            identifier: offerId
        )
        let vc = SharedSceneBuilder.createTransactionDetailsScene(
            sectionsProvider: sectionsProvider,
            routing: routing
        )
        
        vc.navigationItem.title = "Investment details"
        
        return vc
    }
    
    private func showSaleDetailsScreen(identifier: String) {
        let vc = self.setupSaleDetailsScreen(identifier: identifier)
        
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupSaleDetailsScreen(identifier: String) -> SaleDetails.ViewController {
        let vc = SaleDetails.ViewController()
        
        let dataProvider = SaleDetails.SaleDataProvider(
            saleIdentifier: identifier,
            salesRepo: self.reposController.salesRepo,
            assetsRepo: self.reposController.assetsRepo,
            balancesRepo: self.reposController.balancesRepo,
            walletRepo: self.reposController.walletRepo,
            offersRepo: self.reposController.pendingOffersRepo,
            chartsApi: self.flowControllerStack.api.chartsApi,
            imagesUtility: self.reposController.imagesUtility
        )
        
        let amountFormatter = SaleDetails.AmountFormatter()
        
        let dateFormatter = SaleDetails.SaleDetailsDateFormatter()
        
        let chartDateFormatter = SaleDetails.ChartDateFormatter()
        
        let investedAmountFormatter = SaleDetails.InvestAmountFormatter()
        
        let feeLoader = FeeLoader(generalApi: self.flowControllerStack.api.generalApi)
        
        let routing = SaleDetails.Routing(
            onShowProgress: { [weak self] in
                self?.navigationController.showProgress()
            },
            onHideProgress: { [weak self] in
                self?.navigationController.hideProgress()
            },
            onShowError: { [weak self] (errorMessage) in
                self?.navigationController.showErrorMessage(errorMessage, completion: nil)
            },
            onPresentPicker: { [weak self] (title, options, onSelected) in
                self?.navigationController.showDialog(
                    title: title,
                    message: nil,
                    style: .actionSheet,
                    options: options,
                    onSelected: onSelected,
                    onCanceled: nil
                )
            },
            onSaleInvestAction: { [weak self] (investModel) in
                self?.showSaleInvestConfirmationScreen(saleInvestModel: investModel)
            },
            onSaleInfoAction: { [weak self] (infoModel) in
                self?.showSaleInfoScreen(saleInfoModel: infoModel)
        })
        
        SaleDetails.Configurator.configure(
            viewController: vc,
            dataProvider: dataProvider,
            amountFormatter: amountFormatter,
            dateFormatter: dateFormatter,
            chartDateFormatter: chartDateFormatter,
            investedAmountFormatter: investedAmountFormatter,
            feeLoader: feeLoader,
            investorAccountId: self.userDataProvider.walletData.accountId,
            routing: routing
        )
        
        vc.navigationItem.title = "Sale details"
        
        return vc
    }
    
    private func showSaleInvestConfirmationScreen(saleInvestModel: SaleDetails.Model.SaleInvestModel) {
        let vc = self.setupSaleInvestConfirmationScreen(saleInvestModel: saleInvestModel)
        
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupSaleInvestConfirmationScreen(
        saleInvestModel: SaleDetails.Model.SaleInvestModel
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
            percentFormatter: percentFormatter,
            amountPrecision: self.flowControllerStack.apiConfigurationModel.amountPrecision
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
                self?.onShowWalletScreen?()
        })
        
        ConfirmationScene.Configurator.configure(
            viewController: vc,
            sectionsProvider: sectionsProvider,
            routing: routing
        )
        
        vc.navigationItem.title = "Confirmation"
        
        return vc
    }
    
    private func showSaleInfoScreen(saleInfoModel: SaleDetails.Model.SaleInfoModel) {
        let vc = self.setupSaleInfoScene(saleInfoModel: saleInfoModel)
        
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupSaleInfoScene(saleInfoModel: SaleDetails.Model.SaleInfoModel) -> SaleInfo.ViewController {
        let vc = SaleInfo.ViewController()
        let dataProvider = SaleInfo.SaleInfoDataProvider(
            accountId: self.userDataProvider.walletData.accountId,
            saleId: saleInfoModel.saleId,
            blobId: saleInfoModel.blobId,
            asset: saleInfoModel.asset,
            salesApi: self.flowControllerStack.api.salesApi,
            userApi: self.flowControllerStack.usersApi,
            assetsRepo: self.reposController.assetsRepo,
            imagesUtility: self.reposController.imagesUtility,
            balancesRepo: self.reposController.balancesRepo
        )
        
        let routing  = SaleInfo.Routing()
        let sceneModel = SaleInfo.Model.SceneModel(tabs: [])
        let dateFormatter = SaleInfo.DateFormatter()
        let amountFormatter = SaleInfo.AmountFormatter()
        SaleInfo.Configurator.configure(
            viewController: vc,
            sceneModel: sceneModel,
            dataProvider: dataProvider,
            dateFormatter: dateFormatter,
            amountFormatter: amountFormatter,
            routing: routing
        )
        return vc
    }
}
