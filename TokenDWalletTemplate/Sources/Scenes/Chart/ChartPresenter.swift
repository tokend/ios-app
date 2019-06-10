import Foundation

public protocol ChartPresentationLogic {
    typealias Event = Chart.Event
    
    func presentChartDidUpdate(response: Event.ChartDidUpdate.Response)
    func presentSelectChartPeriod(response: Event.SelectChartPeriod.Response)
    func presentSelectChartEntry(response: Event.SelectChartEntry.Response)
}

extension Chart {
    public typealias PresentationLogic = ChartPresentationLogic
    
    @objc(ChartPresenter)
    public class Presenter: NSObject {
        
        public typealias Event = Chart.Event
        public typealias Model = Chart.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        private let amountFormatter: AmountFormatterProtocol
        private let dateFormatter: DateFormatterProtocol
        private let chartDateFormatter: ChartDateFormatterProtocol
        
        // MARK: -
        
        init(
            presenterDispatch: PresenterDispatch,
            amountFormatter: AmountFormatterProtocol,
            dateFormatter: DateFormatterProtocol,
            chartDateFormatter: ChartDateFormatterProtocol
            ) {
            
            self.presenterDispatch = presenterDispatch
            self.amountFormatter = amountFormatter
            self.dateFormatter = dateFormatter
            self.chartDateFormatter = chartDateFormatter
        }
        
        // MARK: - Private
        
        private func createChartViewModel(
            model: Model.ChartModel
            ) -> Model.ChartViewModel {
            
            let formattedAmount = self.amountFormatter.formatAmount(
                model.investedAmount,
                currency: model.asset
            )
            var deployed = Localized(.deployed)
            if let deployedDate = model.investedDate {
                let formattedDate = self.dateFormatter.dateToString(deployedDate)
                deployed.append(" \(formattedDate)")
            }
            
            let datePickerItems = model.datePickerItems.map { (period) -> Model.PeriodViewModel in
                let title = self.titleForPeriod(period)
                return Model.PeriodViewModel(
                    title: title,
                    isEnabled: true,
                    period: period
                )
            }
            
            let formattedGrowth = self.getFormattedGrowthAmount(
                model.growth,
                asset: model.asset
            )
            var formattedGrowthSinceDate = ""
            if let selectedPeriod = model.growthSincePeriod {
                let period = self.titleForPeriod(selectedPeriod).lowercased()
                formattedGrowthSinceDate = Localized(
                    .since_last_period,
                    replace: [
                        .since_last_period_replace_period: period
                    ]
                )
            }
            
            let chartInfoViewModel = self.getChartInfoViewModel(
                model.chartInfoModel,
                asset: model.asset
            )
            
            return Model.ChartViewModel(
                title: formattedAmount,
                subTitle: deployed,
                datePickerItems: datePickerItems,
                selectedDatePickerItemIndex: model.selectedDatePickerItem ?? 0,
                growth: formattedGrowth,
                growthPositive: model.growthPositive,
                growthSinceDate: formattedGrowthSinceDate,
                axisFormatters: self.setupAxisFormatters(
                    periods: model.datePickerItems,
                    selectedPeriodIndex: model.selectedDatePickerItem
                ),
                chartInfoViewModel: chartInfoViewModel
            )
        }
        
        private func titleForPeriod(
            _ period: Model.Period
            ) -> String {
            
            switch period {
            case .hour:
                return Localized(.hour)
            case .day:
                return Localized(.day)
            case .week:
                return Localized(.week)
            case .month:
                return Localized(.month)
            case .year:
                return Localized(.year)
            }
        }
        
        private func getFormattedGrowthAmount(_ amount: Decimal, asset: String) -> String {
            let formattedAmount: String
            if amount == 0.0 {
                formattedAmount = Localized(.no_growth)
            } else {
                let formatted = self.amountFormatter.formatAmount(
                    amount,
                    currency: asset
                )
                if amount > 0 {
                    formattedAmount = "+\(formatted)"
                } else {
                    formattedAmount = formatted
                }
            }
            
            return formattedAmount
        }
        
        private func getChartInfoViewModel(
            _ chartModel: Model.ChartInfoModel,
            asset: String
            ) -> Model.ChartInfoViewModel {
            
            let chartEntries = chartModel.entries.map { (chartEntry) -> Model.ChartDataEntry in
                return Model.ChartDataEntry(
                    x: chartEntry.date.timeIntervalSince1970,
                    y: (chartEntry.value as NSDecimalNumber).doubleValue
                )
            }
            
            let hardCapDecimal = chartModel.limits.first { (limit) -> Bool in
                return limit.type == .hardCap
            }?.value ?? 0
            
            let hardCap = (hardCapDecimal as NSDecimalNumber).doubleValue
            let limitsViewModels = chartModel.limits.map { (limit) -> Model.LimitLineViewModel in
                let doubleValue = (limit.value as NSDecimalNumber).doubleValue
                let label = self.amountFormatter.formatAmount(
                    limit.value,
                    currency: asset
                )
                let percent = doubleValue / hardCap
                return Model.LimitLineViewModel(
                    value: percent,
                    label: label,
                    type: limit.type
                )
            }
            
            let chartInfoViewModel = Model.ChartInfoViewModel(
                entries: chartEntries,
                limits: limitsViewModels
            )
            
            return chartInfoViewModel
        }
        
        private func setupAxisFormatters(
            periods: [Model.Period],
            selectedPeriodIndex: Int?
            ) -> Model.AxisFormatters {
            
            var period: Model.Period?
            if let selectedPeriodIndex = selectedPeriodIndex {
                period = periods[selectedPeriodIndex]
            }
            return Model.AxisFormatters(
                xAxisFormatter: { [weak self] (value) -> String in
                    guard let strongSelf = self,
                        let period = period
                        else {
                            return ""
                    }
                    let date = Date(timeIntervalSince1970: value)
                    return strongSelf.chartDateFormatter.formatDateForXAxis(date, type: period)
                },
                yAxisFormatter: { (_) -> String in
                    return ""
            })
        }
    }
}

extension Chart.Presenter: Chart.PresentationLogic {
    
    public func presentChartDidUpdate(response: Event.ChartDidUpdate.Response) {
        let viewModel: Event.ChartDidUpdate.ViewModel
        switch response {
            
        case .chart(let chartModel):
            let chartViewModel = self.createChartViewModel(model: chartModel)
            viewModel = .chart(chartViewModel)
            
        case .error(let error):
            let errorViewModel = Chart.EmptyContent.ViewModel(
                message: error.localizedDescription
            )
            viewModel = .error(errorViewModel)
        }
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayChartDidUpdate(viewModel: viewModel)
        }
    }
    
    public func presentSelectChartPeriod(response: Event.SelectChartPeriod.Response) {
        let formattedGrowth = self.getFormattedGrowthAmount(
            response.growth,
            asset: response.asset
        )
        var formattedGrowthSinceDate = ""
        if let selectedPeriod = response.growthSincePeriod {
            let period = self.titleForPeriod(selectedPeriod).lowercased()
            formattedGrowthSinceDate = Localized(
                .since_last_period,
                replace: [
                    .since_last_period_replace_period: period
                ]
            )
        }
        
        let chartInfoViewModel = self.getChartInfoViewModel(
            response.chartInfoModel,
            asset: response.asset
        )
        let chartUpdatedViewModel = Model.ChartUpdatedViewModel(
            selectedPeriodIndex: response.selectedPeriodIndex ?? 0,
            growth: formattedGrowth,
            growthPositive: response.growthPositive,
            growthSinceDate: formattedGrowthSinceDate,
            axisFormatters: self.setupAxisFormatters(
                periods: response.periods,
                selectedPeriodIndex: response.selectedPeriodIndex
            ),
            chartInfoViewModel: chartInfoViewModel
        )
        let viewModel = Event.SelectChartPeriod.ViewModel(
            viewModel: chartUpdatedViewModel,
            updatedViewModel: self.createChartViewModel(model: response.updatedModel)
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySelectChartPeriod(viewModel: viewModel)
        }
    }
    
    public func presentSelectChartEntry(response: Event.SelectChartEntry.Response) {
        let formattedAmount = self.amountFormatter.formatAmount(
            response.investedAmount,
            currency: response.asset
        )
        var deployed = Localized(.deployed)
        if let deployedDate = response.investedDate {
            let formattedDate = self.dateFormatter.dateToString(deployedDate)
            deployed.append(" \(formattedDate)")
        }
        
        let chartEntrySelectedViewModel = Model.ChartEntrySelectedViewModel(
            title: formattedAmount,
            subTitle: deployed
        )
        let viewModel = Event.SelectChartEntry.ViewModel(viewModel: chartEntrySelectedViewModel)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySelectChartEntry(viewModel: viewModel)
        }
    }
}

extension Chart.Model.Error: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
            
        case .empty:
            return Localized(.there_is_no_progress_history_yet)
            
        case .other(let error):
            return error.localizedDescription
        }
    }
}
