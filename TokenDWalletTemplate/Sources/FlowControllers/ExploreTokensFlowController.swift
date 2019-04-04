import UIKit

class ExploreTokensFlowController: BaseSignedInFlowController {
    
    typealias Identifier = TransactionsListScene.Identifier
    typealias BalanceId = TransactionsListScene.BalanceId
    
    // MARK: - Private properties
    
    private let navigationController: NavigationControllerProtocol = NavigationController()
    
    // MARK: - Public
    
    public func run(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        self.showTokensListScreen(showRootScreen: showRootScreen)
    }
    
    // MARK: - Private
    
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
        
        let transactionsListRateProvider: TransactionsListScene.RateProviderProtocol = RateProvider(
            assetPairsRepo: self.reposController.assetPairsRepo
        )
        let transactionsFetcher = TransactionsListScene.PaymentsFetcher(
            reposController: self.reposController,
            rateProvider: transactionsListRateProvider,
            originalAccountId: self.userDataProvider.walletData.accountId
        )
        
        let onDidSelectItemWithIdentifier: (Identifier, BalanceId) -> Void = { (_, _) in }
        let showSendPayment:(_ balanceId: String?) -> Void = { (_) in }
        
        let headerRateProvider: BalanceHeaderWithPicker.RateProviderProtocol = RateProvider(
            assetPairsRepo: self.reposController.assetPairsRepo
        )
        let balancesFetcher = BalancesFetcher(
            balancesRepo: self.reposController.balancesRepo
        )
        
        let container = SharedSceneBuilder.createWalletScene(
            transactionsFetcher: transactionsFetcher,
            headerRateProvider: headerRateProvider,
            balancesFetcher: balancesFetcher,
            onDidSelectItemWithIdentifier: onDidSelectItemWithIdentifier,
            showSendPayment: showSendPayment,
            selectedBalanceId: selectedBalanceId
        )
        
        self.navigationController.pushViewController(container, animated: true)
    }
    
    private func openLink(_ link: URL) {
        UIApplication.shared.open(link, options: [:], completionHandler: nil)
    }
}
