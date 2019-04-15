import UIKit

class TradeFlowController: BaseSignedInFlowController {
    
    // MARK: - Private properties
    
    private let navigationController: NavigationController = NavigationController()
    
    // MARK: - Public
    
    public func run(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        self.showTradeScreen(showRootScreen: showRootScreen)
    }
    
    // MARK: - Private
    
    private func showTradeScreen(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        let vc = TradesList.ViewController()
        
        let assetPairsFetcher = TradesList.AssetPairsFetcher(assetPairsRepo: self.reposController.assetPairsRepo)
        
        let amountFormatter = TradesList.AmountFormatter()
        
        let assetColoringProvider = TokenColoringProvider.shared
        
        let routing = TradesList.Routing(
            onSelectAssetPair: { [weak self] (baseAsset, quoteAsset, currentPrice) in
                self?.showOffersScreenFor(
                    baseAsset: baseAsset,
                    quoteAsset: quoteAsset,
                    currentPrice: currentPrice
                )
            },
            onSelectPendingOffers: { [weak self] in
                self?.showPendingOffers()
            },
            onShowError: { [weak self] (errorMessage) in
                self?.navigationController.showErrorMessage(errorMessage, completion: nil)
            },
            onShowProgress: { [weak self] in
                self?.navigationController.showProgress()
            },
            onHideProgress: { [weak self] in
                self?.navigationController.hideProgress()
        })
        
        TradesList.Configurator.configure(
            viewController: vc,
            assetPairsFetcher: assetPairsFetcher,
            amountFormatter: amountFormatter,
            assetColoringProvider: assetColoringProvider,
            routing: routing
        )
        
        vc.navigationItem.title = Localized(.trade)
        
        self.navigationController.setViewControllers([vc], animated: false)
        
        if let showRoot = showRootScreen {
            showRoot(self.navigationController)
        } else {
            self.rootNavigation.setRootContent(self.navigationController, transition: .fade, animated: false)
        }
    }
    
    private func showOffersScreenFor(
        baseAsset: String,
        quoteAsset: String,
        currentPrice: Decimal
        ) {
        
        let vc = self.setupOffersScreenFor(
            baseAsset: baseAsset,
            quoteAsset: quoteAsset,
            currentPrice: currentPrice
        )
        
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupOffersScreenFor(
        baseAsset: String,
        quoteAsset: String,
        currentPrice: Decimal
        ) -> UIViewController {
        
        let vc = TradeOffers.ViewController()
        
        let assetPair = TradeOffers.Model.AssetPair(
            baseAsset: baseAsset,
            quoteAsset: quoteAsset,
            currentPrice: currentPrice
        )
        let sceneModel = TradeOffers.Model.SceneModel(assetPair: assetPair)
        
        let amountFormatter = TradeOffers.AmountFormatter()
        
        let dateFormatter = TradeOffers.TradeDateFormatter()
        
        let chartsFetcher = TradeOffers.ChartsFetcher(
            chartsApi: self.flowControllerStack.api.chartsApi
        )
        
        let offersFetcher = TradeOffers.OffersFetcher(
            orderBookApi: self.flowControllerStack.api.orderBookApi
        )
        
        let routing = TradeOffers.Routing(
            onSelectPendingOffers: <#T##() -> Void#>,
            onDidSelectOffer: <#T##(TradeOffers.Model.Amount, TradeOffers.Model.Amount) -> Void#>,
            onDidSelectNewOffer: <#T##(String, String) -> Void#>,
            onShowError: <#T##(String) -> Void#>,
            onShowProgress: <#T##() -> Void#>,
            onHideProgress: <#T##() -> Void#>
        )
        
        TradeOffers.Configurator.configure(
            viewController: vc,
            sceneModel: sceneModel,
            amountFormatter: amountFormatter,
            dateFormatter: dateFormatter,
            chartsFetcher: chartsFetcher,
            offersFetcher: offersFetcher,
            routing: routing
        )
        
        return vc
    }
    
    private func showCreateOffer(
        baseAsset: String,
        quoteAsset: String,
        amount: Decimal?,
        price: Decimal?
        ) {
        
        let vc = CreateOffer.ViewController()
        
        let sceneModel = CreateOffer.Model.SceneModel(
            baseAsset: baseAsset,
            quoteAsset: quoteAsset,
            amount: amount,
            price: price
        )
        
        let feeLoader = FeeLoader(
            generalApi: self.flowControllerStack.api.generalApi
        )
        let feeLoaderWorker = CreateOffer.FeeLoader(
            feeLoader: feeLoader
        )
        let amountFormatter = CreateOffer.AmountFormatter()
        
        let routing = CreateOffer.Routing(
            showProgress: { [weak self] in
                self?.navigationController.showProgress()
            },
            hideProgress: { [weak self] in
                self?.navigationController.hideProgress()
            },
            onAction: { [weak self] (model) in
                self?.showOfferConfirmation(createOfferModel: model)
            },
            onShowError: { [weak self] (error) in
                self?.navigationController.showErrorMessage(error, completion: nil)
        })
        
        CreateOffer.Configurator.configure(
            viewController: vc,
            accountId: self.userDataProvider.walletData.accountId,
            sceneModel: sceneModel,
            feeLoader: feeLoaderWorker,
            amountFormatter: amountFormatter,
            routing: routing
        )
        
        vc.navigationItem.title = Localized(.create_offer)
        self.navigationController.pushViewController(vc, animated: true)
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
        
        let transactionsListRouting = TransactionsListScene.Routing(
            onDidSelectItemWithIdentifier: { [weak self] (identifier, _) in
                guard let navigationController = self?.navigationController else { return }
                self?.showOfferDetailsScreen(
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
            emptyTitle: Localized(.no_pending_offers),
            viewConfig: viewConfig,
            routing: transactionsListRouting
        )
        
        vc.navigationItem.title = Localized(.pending_offers)
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func showOfferDetailsScreen(
        offerId: UInt64,
        navigationController: NavigationControllerProtocol
        ) {
        
        let vc = self.setupOfferDetailsScreen(
            offerId: offerId,
            navigationController: navigationController
        )
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupOfferDetailsScreen(
        offerId: UInt64,
        navigationController: NavigationControllerProtocol
        ) -> TransactionDetails.ViewController {
        
        let routing = TransactionDetails.Routing(
            successAction: {
                navigationController.popViewController(true)
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
        let sectionsProvider = TransactionDetails.PendingOfferSectionsProvider(
            pendingOffersRepo: self.reposController.pendingOffersRepo,
            transactionSender: self.managersController.transactionSender,
            amountConverter: AmountConverter(),
            networkInfoFetcher: self.flowControllerStack.networkInfoFetcher,
            userDataProvider: self.userDataProvider,
            identifier: offerId
        )
        let vc = SharedSceneBuilder.createTransactionDetailsScene(
            sectionsProvider: sectionsProvider,
            routing: routing
        )
        
        vc.navigationItem.title = Localized(.pending_offer_details)
        
        return vc
    }
    
    private func showOfferConfirmation(
        createOfferModel: CreateOffer.Model.CreateOfferModel
        ) {
        let vc = self.setupOfferConfirmation(
            createOfferModel: createOfferModel
        )
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupOfferConfirmation(
        createOfferModel: CreateOffer.Model.CreateOfferModel
        ) -> ConfirmationScene.ViewController {
        
        let vc = ConfirmationScene.ViewController()
        let amountConverter = AmountConverter()
        let amountFormatter = ConfirmationScene.AmountFormatter()
        let balanceCreator = BalanceCreator(
            balancesRepo: self.reposController.balancesRepo
        )
        
        let offerModel = ConfirmationScene.Model.CreateOfferModel(
            baseAsset: createOfferModel.baseAsset,
            quoteAsset: createOfferModel.quoteAsset,
            isBuy: createOfferModel.isBuy,
            amount: createOfferModel.amount,
            price: createOfferModel.price,
            fee: createOfferModel.fee
        )
        
        let sectionsProvider = ConfirmationScene.CreateOfferConfirmationSectionsProvider(
            createOfferModel: offerModel,
            transactionSender: self.managersController.transactionSender,
            networkInfoFetcher: self.reposController.networkInfoRepo,
            userDataProvider: self.userDataProvider,
            amountFormatter: amountFormatter,
            amountConverter: amountConverter,
            balanceCreator: balanceCreator,
            balancesRepo: self.reposController.balancesRepo
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
                if let viewController = self?.navigationController.viewControllers.first(where: { (vc) -> Bool in
                    return vc is Trade.ViewController
                }) {
                    self?.navigationController.popToViewController(viewController, animated: true)
                }
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
