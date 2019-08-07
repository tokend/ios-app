import UIKit

class ExploreTokensFlowController: BaseSignedInFlowController {
    
    // MARK: - Private properties
    
    private let navigationController: NavigationControllerProtocol = NavigationController()
    
    // MARK: - Public
    
    public func run(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        self.showTokensListScreen(showRootScreen: showRootScreen)
    }
    
    // MARK: - Private
    
    private func showTokensListScreen(showRootScreen: ((_ vc: UIViewController) -> Void)?) {
        
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
            tokensFetcher: tokensFetcher,
            balanceCreator: balanceCreator,
            applicationEventsController: ApplicationEventsController.shared,
            originalAccountId: originalAccountId,
            routing: routing
        )
        
        self.navigationController.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: Theme.Fonts.navigationBarBoldFont,
            NSAttributedString.Key.foregroundColor: Theme.Colors.textOnMainColor
        ]
        
        viewController.navigationItem.title = "Explore Tokens"
        
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
            originalAccountId: originalAccountId,
            routing: routing
        )
        
        self.navigationController.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: Theme.Fonts.navigationBarBoldFont,
            NSAttributedString.Key.foregroundColor: Theme.Colors.textOnMainColor
        ]
        
        viewController.navigationItem.title = "Token details"
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
        let transactionsRouting = TransactionsListScene.Routing { (_, _) in }
        
        let headerRateProvider: BalanceHeaderWithPicker.RateProviderProtocol = RateProvider(
            assetPairsRepo: self.reposController.assetPairsRepo
        )
        let balancesFetcher = BalancesFetcher(
            balancesRepo: self.reposController.balancesRepo
        )
        
        let container = SharedSceneBuilder.createWalletScene(
            transactionsFetcher: transactionsFetcher,
            transactionsRouting: transactionsRouting,
            headerRateProvider: headerRateProvider,
            balancesFetcher: balancesFetcher,
            selectedBalanceId: selectedBalanceId
        )
        
        self.navigationController.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: Theme.Fonts.navigationBarBoldFont,
            NSAttributedString.Key.foregroundColor: Theme.Colors.textOnMainColor
        ]
        self.navigationController.navigationBar.shadowImage = UIImage()
        
        self.navigationController.pushViewController(container, animated: true)
    }
    
    private func openLink(_ link: URL) {
        UIApplication.shared.open(link, options: [:], completionHandler: nil)
    }
}
