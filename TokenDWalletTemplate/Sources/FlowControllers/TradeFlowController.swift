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
        let vc = Trade.ViewController()
        
        let assetsFetcher = Trade.AssetsFetcher(assetPairsRepo: self.reposController.assetPairsRepo)
        
        let chartsFetcher = Trade.ChartsFetcher(
            chartsApi: self.flowControllerStack.api.chartsApi
        )
        let amountFormatter = Trade.AmountFormatter()
        let tradeOffersFetcher = Trade.OffersFetcher(
            orderBookApi: self.flowControllerStack.api.orderBookApi
        )
        
        let routing = Trade.Routing(
            onSelectPendingOffers: { [weak self] in
                self?.showPendingOffers()
            },
            onDidSelectOffer: { [weak self] (baseAmount, price) in
                self?.showCreateOffer(
                    baseAsset: baseAmount.currency,
                    quoteAsset: price.currency,
                    amount: baseAmount.value,
                    price: price.value
                )
            },
            onDidSelectNewOffer: { [weak self] (baseAsset, quoteAsset) in
                self?.showCreateOffer(
                    baseAsset: baseAsset,
                    quoteAsset: quoteAsset,
                    amount: nil,
                    price: nil
                )},
            onShowError: { [weak self] (message) in
                self?.navigationController.showErrorMessage(message, completion: nil)
            },
            onShowProgress: { [weak self] in
                self?.navigationController.showProgress()
            },
            onHideProgress: { [weak self] in
                self?.navigationController.hideProgress()
        })
        
        Trade.Configurator.configure(
            viewController: vc,
            assetsFetcher: assetsFetcher,
            chartsFetcher: chartsFetcher,
            amountFormatter: amountFormatter,
            tradeOffersFetcher: tradeOffersFetcher,
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
