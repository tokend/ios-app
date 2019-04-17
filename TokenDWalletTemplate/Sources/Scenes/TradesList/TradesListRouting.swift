import Foundation

extension TradesList {
    
    public struct Routing {
        
        public let onSelectAssetPair: (
        _ baseAsset: Asset,
        _ quoteAsset: Asset,
        _ currentPrice: Decimal
        ) -> Void
        public let onSelectPendingOffers: () -> Void
        public let onShowError: (_ erroMessage: String) -> Void
        public let onShowProgress: () -> Void
        public let onHideProgress: () -> Void
        
        public init(
            onSelectAssetPair: @escaping (
            _ baseAsset: Asset,
            _ quoteAsset: Asset,
            _ currentPrice: Decimal
            ) -> Void,
            onSelectPendingOffers: @escaping () -> Void,
            onShowError: @escaping (_ erroMessage: String) -> Void,
            onShowProgress: @escaping () -> Void,
            onHideProgress: @escaping () -> Void
            ) {
            
            self.onSelectAssetPair = onSelectAssetPair
            self.onSelectPendingOffers = onSelectPendingOffers
            self.onShowError = onShowError
            self.onShowProgress = onShowProgress
            self.onHideProgress = onHideProgress
        }
    }
}
