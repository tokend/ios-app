import Foundation

public enum TradeOffersOffersFetchResult {
    case succeeded([TradeOffers.Model.Offer])
    case failed
}

public enum TradeOffersTradesFetchResult {
    case succeeded([TradeOffers.Model.Trade])
    case failed
}

public protocol TradeOffersOffersFetcherProtocol {
    
    typealias OffersFetchResult = TradeOffersOffersFetchResult
    
    func getOffers(
        forBuy: Bool,
        base: String,
        quote: String,
        limit: Int,
        cursor: String?,
        completion: @escaping (OffersFetchResult) -> Void
    )
    func cancelOffersRequests()
    
    typealias TradesFetchResult = TradeOffersTradesFetchResult
    
    func getTrades(
        base: String,
        quote: String,
        limit: Int,
        cursor: String?,
        completion: @escaping (TradesFetchResult) -> Void
    )
    func cancelTradesRequests()
}

extension TradeOffers {
    
    public typealias OffersFetcherProtocol = TradeOffersOffersFetcherProtocol
}
