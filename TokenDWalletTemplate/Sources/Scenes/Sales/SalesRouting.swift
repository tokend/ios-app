import Foundation

extension Sales {
    
    struct Routing {
        
        let onDidSelectSale: (_ identifier: String, _ asset: String) -> Void
        let onShowInvestments: () -> Void
        let onShowLoading: () -> Void
        let onHideLoading: () -> Void
        let onShowShadow: () -> Void
        let onHideShadow: () -> Void
    }
}
