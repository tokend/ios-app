import Foundation
import RxSwift

public protocol ChartBusinessLogic {
    typealias Event = Chart.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onSelectChartPeriod(request: Event.SelectChartPeriod.Request)
    func onSelectChartEntry(request: Event.SelectChartEntry.Request)
}

extension Chart {
    public typealias BusinessLogic = ChartBusinessLogic
    
    @objc(ChartInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = Chart.Event
        public typealias Model = Chart.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private var sceneModel: Model.SceneModel
        private let dataProvider: DataProviderProtocol
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: -
        
        init(
            presenter: PresentationLogic,
            sceneModel: Model.SceneModel,
            dataProvider: DataProviderProtocol
            ) {
            
            self.presenter = presenter
            self.sceneModel = sceneModel
            self.dataProvider = dataProvider
        }
        
        // MARK: - Private
        
        private func updateChart() {
            guard
                let sale = self.sceneModel.sale,
                let selected = self.sceneModel.selectedChartsPeriod,
                let charts = self.getChartsForPeriod(selected),
                let lastChart = charts.last else {
                    return
            }
            
            let chartModel = self.getChartModel(
                charts: charts,
                chart: lastChart,
                quoteAsset: sale.quoteAsset,
                softCap: sale.softCap,
                hardCap: sale.hardCap
            )
            let response = Event.ChartDidUpdate.Response.chart(chartModel)
            self.presenter.presentChartDidUpdate(response: response)
        }
        
        private func getChartModel(
            charts: [Model.ChartEntry],
            chart: Model.ChartEntry,
            quoteAsset: String,
            softCap: Decimal,
            hardCap: Decimal
            ) -> Model.ChartModel {
            
            let investedAmount = chart.value
            let investedDate: Date? = self.sceneModel.selectedChartEntryIndex == nil ? nil : chart.date
            let datePickerItems = self.sceneModel.chartsPeriods
            let selectedDatePickerItem = self.getSelectedPeriodIndex()
            let growth = self.getChartGrowthForCharts(charts)
            let growthPositive: Bool? = growth == 0.0 ? nil : growth > 0.0
            var growthSincePeriod: Model.Period?
            if let selectedPeriod = selectedDatePickerItem {
                growthSincePeriod = datePickerItems[selectedPeriod]
            }
            let chartInfoModel = self.getChartInfoModel(
                charts: charts,
                softCap: softCap,
                hardCap: hardCap
            )
            
            let chartModel = Model.ChartModel(
                asset: quoteAsset,
                investedAmount: investedAmount,
                investedDate: investedDate,
                datePickerItems: datePickerItems,
                selectedDatePickerItem: selectedDatePickerItem,
                growth: growth,
                growthPositive: growthPositive,
                growthSincePeriod: growthSincePeriod,
                chartInfoModel: chartInfoModel
            )
            
            return chartModel
        }
        
        private func getChartGrowthForCharts(_ charts: [Model.ChartEntry]) -> Decimal {
            guard let first = charts.first, let last = charts.last else {
                return 0.0
            }
            
            let growth = last.value - first.value
            
            return growth
        }
        
        private func getChartsForPeriod(_ period: Model.Period) -> [Model.ChartEntry]? {
            return self.sceneModel.charts[period]
        }
        
        private func getPeriodPickerItemsForCharts(_ charts: [Model.Period: [Model.ChartEntry]]) -> [Model.Period] {
            var periods = charts.compactMap({ (chartItem) -> Model.Period? in
                return chartItem.value.count > 0 ? chartItem.key : nil
            })
            
            periods.sort { (period1, period2) -> Bool in
                return period1.rawValue <= period2.rawValue
            }
            
            return periods
        }
        
        private func getSelectedPeriodIndex() -> Int? {
            guard let selected = self.sceneModel.selectedChartsPeriod else {
                return nil
            }
            
            return self.sceneModel.chartsPeriods.index(of: selected)
        }
        
        private func getChartInfoModel(
            charts: [Model.ChartEntry],
            softCap: Decimal,
            hardCap: Decimal
            ) -> Model.ChartInfoModel {
            
            let chartMaxValue = charts.max { (entry1, entry2) -> Bool in
                return entry1.value < entry2.value
                }?.value ?? 0.0
            
            let currentLimit = Model.LimitLineModel(
                value: chartMaxValue,
                type: .current
            )
            
            let hardCapLimit = Model.LimitLineModel(
                value: hardCap,
                type: .hardCap
            )
            
            let softCapLimit = Model.LimitLineModel(
                value: softCap,
                type: .softCap
            )
            let chartModel = Model.ChartInfoModel(
                entries: charts,
                limits: [currentLimit, hardCapLimit, softCapLimit]
            )
            
            return chartModel
        }
        
        private func updateChartsPeriods() {
            let periods = self.getPeriodPickerItemsForCharts(self.sceneModel.charts)
            self.sceneModel.chartsPeriods = periods
            
            self.updateSelectedChart()
        }
        
        private func updateSelectedChart() {
            let periods = self.sceneModel.chartsPeriods
            guard periods.count > 0 else {
                self.sceneModel.selectedChartsPeriod = nil
                return
            }
            
            self.sceneModel.selectedChartsPeriod = periods.first
        }
    }
}

extension Chart.Interactor: Chart.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        self.dataProvider
            .observeSale()
            .subscribe(onNext: { [weak self] (sale) in
                self?.sceneModel.sale = sale
            })
            .disposed(by: self.disposeBag)
        
        self.dataProvider
            .observeCharts()
            .subscribe(onNext: { [weak self] (charts) in
                self?.sceneModel.charts = charts
                self?.updateChartsPeriods()
                self?.updateChart()
            })
            .disposed(by: self.disposeBag)
        
        self.dataProvider
            .observeErrors()
            .subscribe(onNext: { [weak self] (error) in
                let response = Event.ChartDidUpdate.Response.error(error)
                self?.presenter.presentChartDidUpdate(response: response)
            })
            .disposed(by: self.disposeBag)
    }
    
    public func onSelectChartPeriod(request: Event.SelectChartPeriod.Request) {
        let periods = self.sceneModel.chartsPeriods
        let selectedPeriod = periods[request.period]
        self.sceneModel.selectedChartsPeriod = selectedPeriod
        
        guard
            let sale = self.sceneModel.sale,
            let selectedPeriodIndex = self.getSelectedPeriodIndex(),
            let charts = self.getChartsForPeriod(selectedPeriod),
            let lastChart = charts.last
            else {
                return
        }
        
        let growth = self.getChartGrowthForCharts(charts)
        let growthPositive: Bool? = growth == 0.0 ? nil : growth > 0.0
        
        let updatedModel = self.getChartModel(
            charts: charts,
            chart: lastChart,
            quoteAsset: sale.quoteAsset,
            softCap: sale.softCap,
            hardCap: sale.hardCap
        )
        
        let chartInfoModel = self.getChartInfoModel(
            charts: charts,
            softCap: sale.softCap,
            hardCap: sale.hardCap
        )
        
        let response = Event.SelectChartPeriod.Response(
            asset: sale.quoteAsset,
            periods: self.sceneModel.chartsPeriods,
            selectedPeriod: selectedPeriod,
            selectedPeriodIndex: selectedPeriodIndex,
            growth: growth,
            growthPositive: growthPositive,
            growthSincePeriod: selectedPeriod,
            chartInfoModel: chartInfoModel,
            updatedModel: updatedModel
        )
        self.presenter.presentSelectChartPeriod(response: response)
    }
    
    public func onSelectChartEntry(request: Event.SelectChartEntry.Request) {
        guard
            let quoteAsset = self.sceneModel.sale?.quoteAsset,
            let selectedPeriod = self.sceneModel.selectedChartsPeriod,
            let charts = self.getChartsForPeriod(selectedPeriod),
            let lastChart = charts.last
            else {
                self.sceneModel.selectedChartEntryIndex = nil
                return
        }
        
        self.sceneModel.selectedChartEntryIndex = request.chartEntryIndex
        
        let chart: Model.ChartEntry
        if let selectedChartEntryIndex = self.sceneModel.selectedChartEntryIndex {
            chart = charts[selectedChartEntryIndex]
        } else {
            chart = lastChart
        }
        
        let investedAmount: Decimal = chart.value
        let investedDate: Date? = self.sceneModel.selectedChartEntryIndex == nil ? nil : chart.date
        
        let response = Event.SelectChartEntry.Response(
            asset: quoteAsset,
            investedAmount: investedAmount,
            investedDate: investedDate
        )
        self.presenter.presentSelectChartEntry(response: response)
    }
}
