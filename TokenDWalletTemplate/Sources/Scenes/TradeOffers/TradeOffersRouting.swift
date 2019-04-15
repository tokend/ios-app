import Foundation

extension TradeOffers {
    
    public struct Routing {
        
        public let onSelectPendingOffers: () -> Void
        public let onDidSelectOffer: (_ baseAmount: Model.Amount, _ price: Model.Amount) -> Void
        public let onDidSelectNewOffer: (_ baseAsset: String, _ quoteAsset: String) -> Void
        public let onShowError: (_ erroMessage: String) -> Void
        public let onShowProgress: () -> Void
        public let onHideProgress: () -> Void
        
        // MARK: -
        
        public init(
            onSelectPendingOffers: @escaping () -> Void,
            onDidSelectOffer: @escaping (_ baseAmount: Model.Amount, _ price: Model.Amount) -> Void,
            onDidSelectNewOffer: @escaping (_ baseAsset: String, _ quoteAsset: String) -> Void,
            onShowError: @escaping (_ erroMessage: String) -> Void,
            onShowProgress: @escaping () -> Void,
            onHideProgress: @escaping () -> Void
            ) {
            
            self.onSelectPendingOffers = onSelectPendingOffers
            self.onDidSelectOffer = onDidSelectOffer
            self.onDidSelectNewOffer = onDidSelectNewOffer
            self.onShowError = onShowError
            self.onShowProgress = onShowProgress
            self.onHideProgress = onHideProgress
        }
    }
}
