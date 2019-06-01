import UIKit

extension TabBarContainer {
    
    class DashboardProvider {
        
        // MARK: - Private properties
        
        private let transactionsFetcher: TransactionsListScene.PaymentsFetcher
        private let balancesFetcher: BalancesList.BalancesFetcherProtocol
        private let actionProvider: TransactionsListScene.ActionProvider
        private let amountFormatter: TransactionsListScene.AmountFormatterProtocol
        private let dateFormatter: TransactionsListScene.DateFormatterProtocol
        private let onDidSelectItemWithIdentifier: (_ id: UInt64, _ balanceId: String) -> Void
        private let showPaymentsFor: ((String) -> Void)
        private let showSendScene: (() -> Void)
        private let showReceiveScene: (() -> Void)
        private let showProgress: (() -> Void)
        private let hideProgress: (() -> Void)
        private let showShadow: (() -> Void)
        private let hideShadow: (() -> Void)
        
        private var content: ContentProtocol?
        
        // MARK: -
        
        init(
            transactionsFetcher: TransactionsListScene.PaymentsFetcher,
            balancesFetcher: BalancesList.BalancesFetcherProtocol,
            actionProvider: TransactionsListScene.ActionProvider,
            amountFormatter: TransactionsListScene.AmountFormatterProtocol,
            dateFormatter: TransactionsListScene.DateFormatterProtocol,
            onDidSelectItemWithIdentifier: @escaping(
            _ id: UInt64,
            _ balanceId: String
            ) -> Void,
            showPaymentsFor: @escaping ((String) -> Void),
            showSendScene: @escaping (() -> Void),
            showReceiveScene: @escaping (() -> Void),
            showProgress: @escaping (() -> Void),
            hideProgress: @escaping (() -> Void),
            showShadow: @escaping (() -> Void),
            hideShadow: @escaping (() -> Void)
            ) {
            
            self.balancesFetcher = balancesFetcher
            self.transactionsFetcher = transactionsFetcher
            self.actionProvider = actionProvider
            self.amountFormatter = amountFormatter
            self.dateFormatter = dateFormatter
            self.onDidSelectItemWithIdentifier = onDidSelectItemWithIdentifier
            self.showPaymentsFor = showPaymentsFor
            self.showSendScene = showSendScene
            self.showReceiveScene = showReceiveScene
            self.showProgress = showProgress
            self.hideProgress = hideProgress
            self.showShadow = showShadow
            self.hideShadow = hideShadow
        }
        
        // MARK: - Private
        
        private func setupTabContainer() -> TabBarContainerContentProtocol {
            let vc = TabsContainer.ViewController()
            
            let balancesTab = self.setupBalancesTab()
            let movementsTab = self.setupMovementsTab()
            let tabs: [TabsContainer.Model.TabModel] = [
                balancesTab,
                movementsTab
            ]
            
            let contentProvider = TabsContainer.InfoContentProvider(tabs: tabs)
            let viewConfig = TabsContainer.Model.ViewConfig(
                isPickerHidden: true,
                isTabBarHidden: false,
                actionButtonAppearence: .hidden
            )
            
            let routing = TabsContainer.Routing(onAction: {
                
            })
            
            TabsContainer.Configurator.configure(
                viewController: vc,
                contentProvider: contentProvider,
                viewConfig: viewConfig,
                routing: routing
            )
            
            self.content = vc
            return vc
        }
        
        private func setupTabBar() -> TabBarContainerTabBarProtocol {
            let tabBar = TabBar.View()
            let sceneModel = TabBar.Model.SceneModel(
                tabs: [],
                selectedTab: nil
            )
            let tabProvider = TabBar.DashboardTabProvider()
            let routing = TabBar.Routing(
                onAction: { [weak self] (identifier) in
                    self?.handleAction(identifier: identifier)
            })
            
            TabBar.Configurator.configure(
                view: tabBar,
                sceneModel: sceneModel,
                tabProvider: tabProvider,
                routing: routing
            )
            
            return tabBar
        }
        
        private func setupBalancesTab() -> TabsContainer.Model.TabModel {
            let vc = BalancesList.ViewController()
            let routing = BalancesList.Routing(
                onBalanceSelected: { [weak self] (balanceId) in
                    self?.showPaymentsFor(balanceId)
                }, showProgress: { [weak self] in
                    self?.showProgress()
                }, hideProgress: { [weak self] in
                    self?.hideProgress()
                }, showShadow: { [weak self] in
                    self?.showShadow()
                }, hideShadow: { [weak self] in
                    self?.hideShadow()
            })
            
            let dataProvider = BalancesList.DataProvider(balancesFetcher: self.balancesFetcher)
            let amountFormatter = BalancesList.AmountFormatter()
            
            BalancesList.Configurator.configure(
                viewController: vc,
                dataProvider: dataProvider,
                amountFormatter: amountFormatter,
                routing: routing
            )
            
            return TabsContainer.Model.TabModel(
                title: Localized(.dashboard),
                content: .viewController(vc),
                identifier: Localized(.balances)
            )
        }
        
        private func setupMovementsTab() -> TabsContainer.Model.TabModel {
            let vc = TransactionsListScene.ViewController()
            let viewConfig = TransactionsListScene.Model.ViewConfig(actionButtonIsHidden: true)
            
            let routing = TransactionsListScene.Routing (
                onDidSelectItemWithIdentifier: { [weak self] (identifier, balanceId) in
                    self?.onDidSelectItemWithIdentifier(identifier, balanceId)
                },
                showSendPayment: { _ in },
                showWithdraw: { _ in },
                showDeposit: { _ in },
                showReceive: {},
                showShadow: { [weak self] in
                    self?.showShadow()
                }, hideShadow: { [weak self] in
                    self?.hideShadow()
                }
            )
            
            TransactionsListScene.Configurator.configure(
                viewController: vc,
                transactionsFetcher: self.transactionsFetcher,
                actionProvider: self.actionProvider,
                amountFormatter: self.amountFormatter,
                dateFormatter: self.dateFormatter,
                emptyTitle: Localized(.no_movements),
                viewConfig: viewConfig,
                routing: routing
            )
            
            return TabsContainer.Model.TabModel(
                title: Localized(.dashboard),
                content: .viewController(vc),
                identifier: Localized(.movements)
            )
        }
        
        private func handleAction(identifier: TabIdentifier) {
            if identifier == Localized(.send) {
                self.showSendScene()
            } else if identifier == Localized(.receive) {
                self.showReceiveScene()
            } else {
                self.content?.setContentWithIdentifier(identifier)
            }
        }
    }
}

extension TabBarContainer.DashboardProvider: TabBarContainer.ContentProviderProtocol {
    
    public func getSceneContent() -> TabBarContainer.Model.SceneContent {
        let content = self.setupTabContainer()
        let tabBar = self.setupTabBar()
        let title = Localized(.dashboard)
        
        return TabBarContainer.Model.SceneContent(
            content: content,
            tabBar: tabBar,
            title: title
        )
    }
}
