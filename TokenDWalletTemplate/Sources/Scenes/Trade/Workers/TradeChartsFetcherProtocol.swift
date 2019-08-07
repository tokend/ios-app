import UIKit

enum TradeChartsFetcherGetChartsResult {
    case success(charts: Trade.Charts)
    case failure
}

protocol TradeChartsFetcherProtocol {
    typealias GetChartsResult = TradeChartsFetcherGetChartsResult
    typealias Completion = (GetChartsResult) -> Void
    
    func getChartsForBaseAsset(
        _ base: String,
        quoteAsset quote: String,
        completion: @escaping Completion
    )
    
    func cancelRequests()
}

extension Trade {
    typealias ChartsFetcherProtocol = TradeChartsFetcherProtocol
}
