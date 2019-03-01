import Foundation
import TokenDSDK

extension Trade {
    
    class ChartsFetcher {
        
        private let chartsApi: ChartsApi
        private var cancelable: Cancelable?
        
        init(
            chartsApi: ChartsApi
            ) {
            
            self.chartsApi = chartsApi
        }
    }
}

extension Trade.ChartsFetcher: Trade.ChartsFetcherProtocol {
    func getChartsForBaseAsset(
        _ base: String,
        quoteAsset quote: String,
        completion: @escaping Completion
        ) {
        
        self.cancelable = self.chartsApi.requestCharts(
            asset: "\(base)-\(quote)",
            completion: { (result) in
                switch result {
                    
                case .success(let chartsResponse):
                    var charts: Trade.Charts = Trade.Charts()
                    for key in chartsResponse.keys {
                        guard let period = Trade.Model.Period(rawValue: key),
                            let chart = chartsResponse[key]
                            else {
                                continue
                        }
                        
                        charts[period] = chart.map({ (chart) -> Trade.Model.Chart in
                            return chart.chart
                        })
                    }
                    
                    completion(.success(charts: charts))
                    
                case .failure:
                    completion(.failure)
                }
        })
    }
    
    func cancelRequests() {
        self.cancelable?.cancel()
    }
}

private extension TokenDSDK.ChartResponse {
    typealias Chart = Trade.Model.Chart
    
    var chart: Chart {
        return Chart(
            date: self.timestamp,
            value: self.value
        )
    }
}
