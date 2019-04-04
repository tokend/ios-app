import UIKit

enum SharedSceneBuilder {
    
    typealias Identifier = TransactionsListScene.Identifier
    typealias BalanceId = TransactionsListScene.BalanceId
    
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
        headerRateProvider: BalanceHeaderWithPicker.RateProviderProtocol,
        balancesFetcher: BalanceHeaderWithPicker.BalancesFetcherProtocol,
        onDidSelectItemWithIdentifier: @escaping (Identifier, BalanceId) -> Void,
        showSendPayment: @escaping (_ balanceId: String?) -> Void,
        selectedBalanceId: BalanceHeaderWithPicker.Identifier? = nil
        ) -> FlexibleHeaderContainerViewController {
        
        let container = FlexibleHeaderContainerViewController()
        
        let viewConfig = TransactionsListScene.Model.ViewConfig(actionButtonIsHidden: false)
        
        let headerView = BalanceHeaderWithPicker.View(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let headerSceneModel = BalanceHeaderWithPicker.Model.SceneModel(
            balances: [],
            selectedBalanceId: selectedBalanceId
        )
        let headerAmountFormatter = BalanceHeaderWithPicker.AmountFormatter()
        
        let transactionsRouting = TransactionsListScene.Routing(
            onDidSelectItemWithIdentifier: onDidSelectItemWithIdentifier,
            showSendPayment: showSendPayment,
            updateBalancesRequest: {
                headerView.requestUpdateBalances()
        })
        
        let viewController = SharedSceneBuilder.createTransactionsListScene(
            transactionsFetcher: transactionsFetcher,
            emptyTitle: Localized(.no_payments),
            viewConfig: viewConfig,
            routing: transactionsRouting
        )
        
        let balancesRouting = BalanceHeaderWithPicker.Routing { (balanceId, asset) in
            viewController.balanceId = balanceId
            viewController.asset = asset
        }
        
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
}
