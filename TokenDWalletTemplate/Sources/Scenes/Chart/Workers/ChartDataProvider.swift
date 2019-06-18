import UIKit
import RxSwift
import RxCocoa
import TokenDSDK

protocol ChartDataProviderProtocol {
    func observeCharts() -> Observable<[Chart.Model.Period: [Chart.Model.ChartEntry]]>
    func observeSale() -> Observable<Chart.Model.SaleModel?>
    func observeErrors() -> Observable<Swift.Error>
}

extension Chart {
    typealias DataProviderProtocol = ChartDataProviderProtocol
    
    class DataProvider: DataProviderProtocol {
        
        private typealias ChartPeriod = Chart.Model.Period
        private typealias ChartEntry = Chart.Model.ChartEntry
        
        // MARK: - Private properties
        
        private let saleIdentifier: String
        private let salesRepo: SalesRepo
        private let chartsApi: ChartsApi
        
        private let charts: BehaviorRelay<TokenDSDK.ChartsResponse> = BehaviorRelay(value: [:])
        private let errors: PublishRelay<Swift.Error> = PublishRelay()
        
        // MARK: -
        
        init(
            saleIdentifier: String,
            salesRepo: SalesRepo,
            chartsApi: ChartsApi
            ) {
            
            self.saleIdentifier = saleIdentifier
            self.salesRepo = salesRepo
            self.chartsApi = chartsApi
        }
        
        // MARK: - Public
        
        func observeCharts() -> Observable<[Model.Period: [Model.ChartEntry]]> {
            return self.charts.map({ (chartsResponse) -> [Model.Period: [Model.ChartEntry]] in
                var charts = [Model.Period: [Model.ChartEntry]]()
                for key in chartsResponse.keys {
                    guard let period = Model.Period(string: key),
                        let chart = chartsResponse[key]
                        else {
                            continue
                    }
                    
                    charts[period] = chart.map({ (chart) -> Model.ChartEntry in
                        return chart.chart
                    })
                }
                
                return charts
            })
        }
        
        func observeSale() -> Observable<Chart.Model.SaleModel?> {
            return self.salesRepo.observeSale(id: self.saleIdentifier).map({ [weak self] (sale) -> Model.SaleModel? in
                guard let sale = sale else {
                    return nil
                }
                self?.loadCharts(saleAsset: sale.baseAsset)
                
                return Model.SaleModel(
                    baseAsset: sale.baseAsset,
                    quoteAsset: sale.defaultQuoteAsset,
                    softCap: sale.softCap,
                    hardCap: sale.hardCap
                )
            })
        }
        
        func observeErrors() -> Observable<Error> {
            return self.errors.asObservable()
        }
        
        // MARK: - Private
        
        private func loadCharts(saleAsset: String) {
            self.chartsApi.requestCharts(
                asset: saleAsset,
                completion: { [weak self] (result) in
                    switch result {
                        
                    case .failure(let apiError):
                        let error: Model.Error
                        if apiError.contains(status: Model.ErrorStatus.notFound.rawValue) {
                            error = .empty
                        } else {
                            error = .other(apiError)
                        }
                        self?.errors.accept(error)
                        
                    case .success(let charts):
                        self?.charts.accept(charts)
                    }
            })
        }
    }
}

private extension TokenDSDK.ChartResponse {
    typealias ChartEntry = Chart.Model.ChartEntry
    
    var chart: ChartEntry {
        return ChartEntry(
            date: self.timestamp,
            value: self.value
        )
    }
}
