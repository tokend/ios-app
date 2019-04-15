import UIKit

public enum TradeOffersChartsFetcherGetChartsResult {
    case success(charts: TradeOffers.Model.Charts)
    case failure
}

public protocol TradeOffersChartsFetcherProtocol {
    
    typealias GetChartsResult = TradeOffersChartsFetcherGetChartsResult
    typealias Completion = (GetChartsResult) -> Void
    
    func getChartsForBaseAsset(
        _ base: String,
        quoteAsset quote: String,
        completion: @escaping Completion
    )
    
    func cancelRequests()
}

extension TradeOffers {
    public typealias ChartsFetcherProtocol = TradeOffersChartsFetcherProtocol
}
