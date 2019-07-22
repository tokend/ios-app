import UIKit

enum SharedSceneBuilder {
    
    public static func createTransactionDetailsScene(
        sectionsProvider: TransactionDetails.SectionsProviderProtocol,
        routing: TransactionDetails.Routing
        ) -> TransactionDetails.ViewController {
        
        let vc = TransactionDetails.ViewController()
        
        let sceneModel = TransactionDetails.Model.SceneModel()
        
        TransactionDetails.Configurator.configure(
            viewController: vc,
            sectionsProvider: sectionsProvider,
            sceneModel: sceneModel,
            routing: routing
        )
        return vc
    }
    
    public static func createTransactionsListScene(
        transactionsFetcher: TransactionsListScene.TransactionsFetcherProtocol,
        actionProvider: TransactionsListScene.ActionProviderProtocol,
        emptyTitle: String,
        viewConfig: TransactionsListScene.Model.ViewConfig,
        routing: TransactionsListScene.Routing
        ) -> TransactionsListScene.ViewController {
        
        let vc = TransactionsListScene.ViewController()
        
        let transactionsListAmountFormatter = TransactionsListScene.AmountFormatter()
        let transactionsListDateFormatter = TransactionsListScene.DateFormatter()
        
        TransactionsListScene.Configurator.configure(
            viewController: vc,
            transactionsFetcher: transactionsFetcher,
            actionProvider: actionProvider,
            amountFormatter: transactionsListAmountFormatter,
            dateFormatter: transactionsListDateFormatter,
            emptyTitle: emptyTitle,
            viewConfig: viewConfig,
            routing: routing
        )
        
        return vc
    }
    
    public static func createWalletScene(
        transactionsFetcher: TransactionsListScene.TransactionsFetcherProtocol,
        actionProvider: TransactionsListScene.ActionProviderProtocol,
        transactionsRouting: TransactionsListScene.Routing,
        viewConfig: TransactionsListScene.Model.ViewConfig,
        headerRateProvider: BalanceHeaderWithPicker.RateProviderProtocol,
        balancesFetcher: BalanceHeaderWithPicker.BalancesFetcherProtocol,
        selectedBalanceId: BalanceHeaderWithPicker.Identifier? = nil
        ) -> FlexibleHeaderContainerViewController {
        
        let container = FlexibleHeaderContainerViewController()
        
        let viewController = SharedSceneBuilder.createTransactionsListScene(
            transactionsFetcher: transactionsFetcher,
            actionProvider: actionProvider,
            emptyTitle: Localized(.no_payments),
            viewConfig: viewConfig,
            routing: transactionsRouting
        )
        
        let balancesRouting = BalanceHeaderWithPicker.Routing { (balanceId, asset) in
            viewController.balanceId = balanceId
            viewController.asset = asset
        }
        
        let headerView = BalanceHeaderWithPicker.View(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let headerSceneModel = BalanceHeaderWithPicker.Model.SceneModel(
            balances: [],
            selectedBalanceId: selectedBalanceId
        )
        let headerAmountFormatter = BalanceHeaderWithPicker.AmountFormatter()
        
        BalanceHeaderWithPicker.Configurator.configure(
            view: headerView,
            sceneModel: headerSceneModel,
            amountFormatter: headerAmountFormatter,
            balancesFetcher: balancesFetcher,
            rateProvider: headerRateProvider,
            routing: balancesRouting
        )
        
        container.contentViewController = viewController
        container.headerView = headerView
        
        return container
    }
    
    public static func createBalanceDetailsScene(
        transactionsFetcher: TransactionsListScene.TransactionsFetcherProtocol,
        actionProvider: TransactionsListScene.ActionProviderProtocol,
        transactionsRouting: TransactionsListScene.Routing,
        viewConfig: TransactionsListScene.Model.ViewConfig,
        balanceFetcher: BalanceHeader.BalanceFetcherProtocol,
        balanceId: String
        ) -> FlexibleHeaderContainerViewController {
        
        let container = FlexibleHeaderContainerViewController()
        
        let viewController = SharedSceneBuilder.createTransactionsListScene(
            transactionsFetcher: transactionsFetcher,
            actionProvider: actionProvider,
            emptyTitle: Localized(.no_payments),
            viewConfig: viewConfig,
            routing: transactionsRouting
        )
        
        let balancesRouting = BalanceHeader.Routing()
        
        let headerView = BalanceHeader.View(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let headerSceneModel = BalanceHeader.Model.SceneModel(
            balance: nil,
            balanceId: balanceId
        )
        let headerAmountFormatter = BalanceHeader.AmountFormatter()
        
        BalanceHeader.Configurator.configure(
            view: headerView,
            sceneModel: headerSceneModel,
            balanceFetcher: balanceFetcher,
            amountFormatter: headerAmountFormatter,
            routing: balancesRouting
        )
        
        viewController.balanceId = balanceId
        container.contentViewController = viewController
        container.headerView = headerView
        
        return container
    }
}
