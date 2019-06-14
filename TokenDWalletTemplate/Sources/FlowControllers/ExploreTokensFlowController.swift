import UIKit

class ExploreTokensFlowController: BaseSignedInFlowController {
    
    // MARK: - Private properties
    
    private let navigationController: NavigationControllerProtocol
    private weak var walletScene: UIViewController?
    private var operationCompletionScene: UIViewController {
        return self.walletScene ?? UIViewController()
    }
    
    // MARK: -
    
    init(
        navigationController: NavigationControllerProtocol,
        appController: AppControllerProtocol,
        flowControllerStack: FlowControllerStack,
        reposController: ReposController,
        managersController: ManagersController,
        userDataProvider: UserDataProviderProtocol,
        keychainDataProvider: KeychainDataProviderProtocol,
        rootNavigation: RootNavigationProtocol
        ) {
        
        self.navigationController = navigationController
        super.init(
            appController: appController,
            flowControllerStack: flowControllerStack,
            reposController: reposController,
            managersController: managersController,
            userDataProvider: userDataProvider,
            keychainDataProvider: keychainDataProvider,
            rootNavigation: rootNavigation
        )
    }
    
    // MARK: - Public
    
    public func run(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        self.showTokensListScreen(showRootScreen: showRootScreen)
    }
    
    // MARK: - Private
    
    private func goBackToWalletScene() {
        _ = self.navigationController.popToViewController(
            self.operationCompletionScene,
            animated: true
        )
    }
    
    private func showTokensListScreen(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        let tokenColoringProvider = TokenColoringProvider.shared
        
        let originalAccountId = self.userDataProvider.walletData.accountId
        let viewController = ExploreTokensScene.ViewController()
        
        let tokensFetcher = ExploreTokensScene.TokensFetcher(
            assetsRepo: self.reposController.assetsRepo,
            imagesUtility: self.reposController.imagesUtility,
            balancesRepo: self.reposController.balancesRepo
        )
        let balanceCreator = BalanceCreator(
            balancesRepo: self.reposController.balancesRepo
        )
        
        let routing = ExploreTokensScene.Routing(
            onDidSelectToken: { [weak self] (identifier) in
                self?.showTokenDetails(identifier)
            },
            onDidSelectHistoryForBalance: { [weak self] (balanceId) in
                self?.showTokenTransactionsHistoryFor(selectedBalanceId: balanceId)
            },
            onError: { [weak self] (message) in
                self?.navigationController.showErrorMessage(message, completion: nil)
        })
        
        ExploreTokensScene.Configurator.configure(
            viewController: viewController,
            tokenColoringProvider: tokenColoringProvider,
            tokensFetcher: tokensFetcher,
            balanceCreator: balanceCreator,
            applicationEventsController: ApplicationEventsController.shared,
            originalAccountId: originalAccountId,
            routing: routing
        )
        
        viewController.navigationItem.title = Localized(.assets)
        
        self.navigationController.pushViewController(viewController, animated: true)
    }
    
    private func showTokenDetails(_ tokenIdentifier: String) {
        
        let originalAccountId = self.userDataProvider.walletData.accountId
        let viewController = TokenDetailsScene.ViewController()
        
        let documentUrlBuilder = TokenDetailsScene.DocumentURLBuilder(
            apiConfiguration: self.flowControllerStack.apiConfigurationModel
        )
        
        let tokenDetailsFetcher: TokenDetailsFetcherProtocol = TokenDetailsScene.TokenDetailsFetcher(
            assetsRepo: self.reposController.assetsRepo,
            balancesRepo: self.reposController.balancesRepo,
            imagesUtility: self.reposController.imagesUtility,
            documentURLBuilder: documentUrlBuilder
        )
        let balanceCreator: TokenDetailsScene.BalanceCreatorProtocol = BalanceCreator(
            balancesRepo: self.reposController.balancesRepo
        )
        let amountFormatter: TokenDetailsScene.AmountFormatterProtocol = TokenDetailsScene.AmountFormatter()
        
        let tokenColoringProvider = TokenColoringProvider.shared
        
        let routing = TokenDetailsScene.Routing(
            onDidSelectHistoryForBalance: { [weak self] (balanceId) in
                self?.showTokenTransactionsHistoryFor(selectedBalanceId: balanceId)
            },
            onDidSelectDocument: { [weak self] (link) in
                self?.openLink(link)
            }, showSeparator: { [weak self] in
                self?.navigationController.showShadow()
            },
               hideSeparator: { [weak self] in
                self?.navigationController.hideShadow()
        })
        
        TokenDetailsScene.Configurator.configure(
            viewController: viewController,
            tokenIdentifier: tokenIdentifier,
            balanceCreator: balanceCreator,
            tokenDetailsFetcher: tokenDetailsFetcher,
            amountFormatter: amountFormatter,
            tokenColoringProvider: tokenColoringProvider,
            originalAccountId: originalAccountId,
            routing: routing
        )
        
        viewController.navigationItem.title = Localized(.asset_details)
        self.navigationController.pushViewController(viewController, animated: true)
    }
    
    private func showTokenTransactionsHistoryFor(selectedBalanceId: String) {
        let transactionsProvider = TransactionsListScene.HistoryProvider(
            reposController: self.reposController,
            originalAccountId: self.userDataProvider.walletData.accountId
        )
        let transactionsFetcher = TransactionsListScene.PaymentsFetcher(
            transactionsProvider: transactionsProvider
        )
        let actionProvider = TransactionsListScene.ActionProvider(
            assetsRepo: self.reposController.assetsRepo,
            balancesRepo: self.reposController.balancesRepo
        )
        let viewConfig = TransactionsListScene.Model.ViewConfig(actionButtonIsHidden: false)
        
        let navigationController = self.navigationController
        let transactionsRouting = TransactionsListScene.Routing (
            onDidSelectItemWithIdentifier: { [weak self] (identifier, balanceId) in
                self?.showTransactionDetailsScreen(
                    transactionsProvider: transactionsProvider,
                    navigationController: navigationController,
                    transactionId: identifier,
                    balanceId: balanceId
                )
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
            },
            showShadow: { [weak self] in
                self?.navigationController.showShadow()
            },
            hideShadow: { [weak self] in
                self?.navigationController.hideShadow()
        })
        
        let headerRateProvider: BalanceHeaderWithPicker.RateProviderProtocol = RateProvider(
            assetPairsRepo: self.reposController.assetPairsRepo
        )
        let imageUtility = ImagesUtility(
            storageUrl: self.flowControllerStack.apiConfigurationModel.storageEndpoint
        )
        let balanceFetcher = BalanceHeader.BalancesFetcher(
            balancesRepo: self.reposController.balancesRepo,
            assetsRepo: self.reposController.assetsRepo,
            imageUtility: imageUtility,
            balanceId: selectedBalanceId
        )
        let container = SharedSceneBuilder.createBalanceDetailsScene(
            transactionsFetcher: transactionsFetcher,
            actionProvider: actionProvider,
            transactionsRouting: transactionsRouting,
            viewConfig: viewConfig,
            headerRateProvider: headerRateProvider,
            balanceFetcher: balanceFetcher,
            balanceId: selectedBalanceId
        )
        
        self.walletScene = container
        self.navigationController.pushViewController(container, animated: true)
    }
    
    private func openLink(_ link: URL) {
        UIApplication.shared.open(link, options: [:], completionHandler: nil)
    }
}
