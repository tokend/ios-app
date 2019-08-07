import Foundation

extension Sales {
    struct Routing {
        let onDidSelectSale: (_ identifier: String) -> Void
        let onShowInvestments: () -> Void
        let onShowLoading: () -> Void
        let onHideLoading: () -> Void
    }
}
