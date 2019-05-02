import UIKit

class ExploreTokensFlowController: BaseSignedInFlowController {
    
    // MARK: - Private properties
    
    private let navigationController: NavigationControllerProtocol = NavigationController()
    private weak var walletScene: UIViewController?
    private var operationCompletionScene: UIViewController {
        return self.walletScene ?? UIViewController()
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
        
        viewController.navigationItem.title = Localized(.explore_tokens)
        
        self.navigationController.setViewControllers([viewController], animated: false)
        
        if let showRoot = showRootScreen {
            showRoot(self.navigationController.getViewController())
        } else {
            self.rootNavigation.setRootContent(self.navigationController, transition: .fade, animated: false)
        }
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
        
        viewController.navigationItem.title = Localized(.token_details)
        self.navigationController.pushViewController(viewController, animated: true)
    }
    
    private func showTokenTransactionsHistoryFor(selectedBalanceId: String) {
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

        let headerRateProvider: BalanceHeaderWithPicker.RateProviderProtocol = RateProvider(
            assetPairsRepo: self.reposController.assetPairsRepo
        )
        let balancesFetcher = BalancesFetcher(
            balancesRepo: self.reposController.balancesRepo
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
    
    private func showTransactionDetailsScreen(
        transactionId: UInt64,
        balanceId: String
        ) {
        let vc = self.setupTransactionDetailsScreen(
            transactionId: transactionId,
            balanceId: balanceId
        )
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    private func setupTransactionDetailsScreen(
        transactionId: UInt64,
        balanceId: String
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
        let vc = SharedSceneBuilder.createTransactionDetailsScene(
            sectionsProvider: sectionsProvider,
            routing: routing
        )
        
        vc.navigationItem.title = Localized(.transaction_details)
        
        return vc
    }
    
    private func openLink(_ link: URL) {
        UIApplication.shared.open(link, options: [:], completionHandler: nil)
    }
}
