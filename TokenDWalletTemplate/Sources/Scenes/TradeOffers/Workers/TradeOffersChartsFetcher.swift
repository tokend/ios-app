import Foundation
import TokenDSDK

extension TradeOffers {
    
    public class ChartsFetcher {
        
        private let chartsApi: ChartsApi
        private var cancelable: Cancelable?
        
        public init(
            chartsApi: ChartsApi
            ) {
            
            self.chartsApi = chartsApi
        }
    }
}

extension TradeOffers.ChartsFetcher: TradeOffers.ChartsFetcherProtocol {
    
    public func getChartsForBaseAsset(
        _ base: String,
        quoteAsset quote: String,
        completion: @escaping Completion
        ) {
        
        self.cancelable = self.chartsApi.requestCharts(
            asset: "\(base)-\(quote)",
            completion: { (result) in
                switch result {
                    
                case .success(let chartsResponse):
                    var charts = TradeOffers.Model.Charts()
                    for key in chartsResponse.keys {
                        guard let period = TradeOffers.Model.Period(rawValue: key),
                            let chart = chartsResponse[key]
                            else {
                                continue
                        }
                        
                        charts[period] = chart.map({ (chart) -> TradeOffers.Model.Chart in
                            return chart.chart
                        })
                    }
                    
                    completion(.success(charts: charts))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
        })
    }
    
    public func cancelRequests() {
        self.cancelable?.cancel()
    }
}

extension TokenDSDK.ChartResponse {
    fileprivate typealias Chart = TradeOffers.Model.Chart
    
    fileprivate var chart: Chart {
        return Chart(
            date: self.timestamp,
            value: self.value
        )
    }
}
