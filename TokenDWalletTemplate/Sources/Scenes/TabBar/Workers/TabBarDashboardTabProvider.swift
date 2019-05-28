import Foundation

extension TabBar {
    
    class DashboardTabProvider: TabProviderProtocol {
        
        // MARK: - TabProviderProtocol
        
        func getTabs() -> [TabBar.Model.TabItem] {
            let balancesTab = Model.TabItem(
                title: Localized(.balances),
                image: Assets.amount.image,
                identifier: Localized(.balances),
                isSelectable: true
            )
            let sendTab = Model.TabItem(
                title: Localized(.send),
                image: Assets.send.image,
                identifier: Localized(.send),
                isSelectable: false
            )
            let receiveTab = Model.TabItem(
                title: Localized(.receive),
                image: Assets.receive.image,
                identifier: Localized(.receive),
                isSelectable: false
            )
            
            return [balancesTab, sendTab, receiveTab]
        }
    }
}
