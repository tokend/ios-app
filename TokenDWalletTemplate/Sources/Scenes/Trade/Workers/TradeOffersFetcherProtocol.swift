import Foundation

enum TradeOffersFetchResult {
    case succeeded([Trade.Model.Offer])
    case failed
}

protocol TradeOffersFetcherProtocol {
    func cancelRequests()
    func getOffers(
        forBuy: Bool,
        base: String,
        quote: String,
        completion: @escaping (TradeOffersFetchResult) -> Void
    )
}

extension Trade {
    typealias OffersFetcherProtocol = TradeOffersFetcherProtocol
    typealias OffersFetchResult = TradeOffersFetchResult
}
