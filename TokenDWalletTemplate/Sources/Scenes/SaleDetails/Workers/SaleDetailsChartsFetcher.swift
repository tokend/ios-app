import Foundation
import TokenDSDK

extension SaleDetails {
    
    class ChartsFetcher {
        
        private let chartsApi: TokenDSDK.ChartsApi
        private var cancelable: Cancelable?
        
        init(
            chartsApi: TokenDSDK.ChartsApi
            ) {
            
            self.chartsApi = chartsApi
        }
    }
}

extension SaleDetails.ChartsFetcher: SaleDetails.ChartsFetcherProtocol {
    
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
                    var charts: [SaleDetails.Model.Period: [SaleDetails.Model.ChartEntry]] = [:]
                    for key in chartsResponse.keys {
                        guard let period = SaleDetails.Model.Period(string: key),
                            let chart = chartsResponse[key]
                            else {
                                continue
                        }
                        
                        charts[period] = chart.map({ (chart) -> SaleDetails.Model.ChartEntry in
                            return chart.chart
                        })
                    }
                    
                    completion(.success(charts: charts))
                    
                case .failure(let errors):
                    completion(.failure(errors))
                }
        })
    }
    
    func cancelRequests() {
        self.cancelable?.cancel()
    }
}

private extension TokenDSDK.ChartResponse {
    
    typealias Chart = SaleDetails.Model.ChartEntry
    
    var chart: Chart {
        return Chart(
            date: self.timestamp,
            value: self.value
        )
    }
}
