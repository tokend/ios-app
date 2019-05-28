import UIKit

extension TabBarContainer {
    
    class DashboardProvider {
        
        // MARK: - Private properties
        
        private let balancesRepo: BalancesRepo
        private let showPaymentsFor: ((String) -> Void)
        private let showSendScene: (() -> Void)
        private let showReceiveScene: (() -> Void)
        private let showProgress: (() -> Void)
        private let hideProgress: (() -> Void)
        
        private var content: ContentProtocol?
        
        // MARK: -
        
        init(
            balancesRepo: BalancesRepo,
            showPaymentsFor: @escaping ((String) -> Void),
            showSendScene: @escaping (() -> Void),
            showReceiveScene: @escaping (() -> Void),
            showProgress: @escaping (() -> Void),
            hideProgress: @escaping (() -> Void)
            ) {
            
            self.balancesRepo = balancesRepo
            self.showPaymentsFor = showPaymentsFor
            self.showSendScene = showSendScene
            self.showReceiveScene = showReceiveScene
            self.showProgress = showProgress
            self.hideProgress = hideProgress
        }
        
        // MARK: - Private
        
        private func setupTabContainer() -> TabBarContainerContentProtocol {
            let vc = TabsContainer.ViewController()
            
            let balancesTab = self.setupBalancesTab()
            let tabs: [TabsContainer.Model.TabModel] = [
                balancesTab
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
            })
            
            let balancesFetcher = BalancesList.BalancesFetcher(
                balancesRepo: balancesRepo
            )
            let dataProvider = BalancesList.DataProvider(balancesFetcher: balancesFetcher)
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
