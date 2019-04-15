import Foundation

public enum TradeOffersOffersFetchResult {
    case succeeded([TradeOffers.Model.Offer])
    case failed
}

public protocol TradeOffersOffersFetcherProtocol {
    
    typealias OffersFetchResult = TradeOffersOffersFetchResult
    
    func cancelRequests()
    func getOffers(
        forBuy: Bool,
        base: String,
        quote: String,
        completion: @escaping (OffersFetchResult) -> Void
    )
}

extension TradeOffers {
    
    public typealias OffersFetcherProtocol = TradeOffersOffersFetcherProtocol
}
