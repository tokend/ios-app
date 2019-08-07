import Foundation

enum SaleDetailsChartsFetcherResult {
    case failure(Swift.Error)
    case success(charts: [SaleDetails.Model.Period: [SaleDetails.Model.ChartEntry]])
}

protocol SaleDetailsChartsFetcherProtocol {
    typealias Result = SaleDetailsChartsFetcherResult
    typealias Completion = (Result) -> Void
    
    func getChartsForBaseAsset(
        _ base: String,
        quoteAsset quote: String,
        completion: @escaping Completion
    )
    
    func cancelRequests()
}

extension SaleDetails {
    typealias ChartsFetcherProtocol = SaleDetailsChartsFetcherProtocol
}
