import Foundation

extension Trade {
    struct Routing {
        let onSelectPendingOffers: () -> Void
        let onDidSelectOffer: (_ baseAmount: Model.Amount, _ price: Model.Amount) -> Void
        let onDidSelectNewOffer: (_ baseAsset: String, _ quoteAsset: String) -> Void
        let onShowError: (_ erroMessage: String) -> Void
        let onShowProgress: () -> Void
        let onHideProgress: () -> Void
    }
}
