import Foundation
import RxSwift
import RxCocoa

extension TabBar {
    
    class TabProvider {

        // MARK: - Private properties

        private let tabsBehaviorRelay: BehaviorRelay<[TabBar.Model.TabItem]> = .init(value: [])

        // MARK: -

        init(
            order: [TabBarFlowController.Tab]
        ) {

            var tabs: [TabBar.Model.TabItem] = []

            for tab in order {
                switch tab {
                
                case .balances:
                    let balancesTab: Model.TabItem = .init(
                        title: "Balances",
                        image: Assets.arrow_back_icon.image,
                        identifier: tab.rawValue
                    )
                    tabs.append(balancesTab)
                    
                case .movements:
                    let movementsTab: Model.TabItem = .init(
                        title: "Movements",
                        image: Assets.arrow_right_icon.image,
                        identifier: tab.rawValue
                    )
                    tabs.append(movementsTab)
                }
            }
            tabsBehaviorRelay.accept(tabs)
        }
    }
}

extension TabBar.TabProvider: TabBar.TabProviderProtocol {

    var tabs: [TabBar.Model.TabItem] {
        tabsBehaviorRelay.value
    }

    func observeTabs() -> Observable<[TabBar.Model.TabItem]> {
        tabsBehaviorRelay.asObservable()
    }
}

