import UIKit

protocol SaleDetailsPresentationLogic {
    
    typealias Event = SaleDetails.Event
    
    func presentTabsUpdated(response: Event.TabsUpdated.Response)
    func presentSelectBalance(response: Event.SelectBalance.Response)
    func presentBalanceSelected(response: Event.BalanceSelected.Response)
    func presentInvestAction(response: Event.InvestAction.Response)
    func presentCancelInvestAction(response: Event.CancelInvestAction.Response)
    func presentSelectChartPeriod(response: Event.SelectChartPeriod.Response)
    func presentSelectChartEntry(response: Event.SelectChartEntry.Response)
    func presentTabWasSelected(response: Event.TabWasSelected.Response)
}

extension SaleDetails {
    
    typealias PresentationLogic = SaleDetailsPresentationLogic
    
    class Presenter {
        
        typealias Event = SaleDetails.Event
        typealias Model = SaleDetails.Model
        
        private let presenterDispatch: PresenterDispatch
        private let amountFormatter: AmountFormatterProtocol
        private let dateFormatter: DateFormatterProtocol
        private let chartDateFormatter: ChartDateFormatterProtocol
        private let investedAmountFormatter: InvestedAmountFormatter
        private let overviewFormatter: SaleDetails.TextFormatter
        
        private let verticalSpacing: CGFloat = 5.0
        
        // MARK: -
        
        init(
            presenterDispatch: PresenterDispatch,
            amountFormatter: AmountFormatterProtocol,
            dateFormatter: DateFormatterProtocol,
            chartDateFormatter: ChartDateFormatterProtocol,
            investedAmountFormatter: InvestedAmountFormatter,
            overviewFormatter: SaleDetails.TextFormatter
            ) {
            
            self.presenterDispatch = presenterDispatch
            self.amountFormatter = amountFormatter
            self.dateFormatter = dateFormatter
            self.chartDateFormatter = chartDateFormatter
            self.investedAmountFormatter = investedAmountFormatter
            self.overviewFormatter = overviewFormatter
        }
        
        // MARK: - Private
        
        private func getTimeText(
            sale: Model.OverviewTabModel
            ) -> (timeText: NSAttributedString, isUpcomming: Bool) {
            
            let isUpcomming: Bool
            let attributedDaysRemaining: NSAttributedString
            
            if sale.startDate > Date() {
                isUpcomming = true
                
                let components = Calendar.current.dateComponents(
                    [Calendar.Component.day],
                    from: Date(),
                    to: sale.startDate
                )
                
                let days = "\(components.day ?? 0)"
                let daysAttributed = NSAttributedString(
                    string: days,
                    attributes: [
                        .foregroundColor: Theme.Colors.accentColor
                    ]
                )
                
                attributedDaysRemaining = LocalizedAtrributed(
                    .days_to_start,
                    attributes: [
                        .foregroundColor: Theme.Colors.textOnContentBackgroundColor
                    ],
                    replace: [
                        .days_to_start_replace_days: daysAttributed
                    ]
                )
            } else {
                isUpcomming = false
                
                let components = Calendar.current.dateComponents(
                    [Calendar.Component.day],
                    from: Date(),
                    to: sale.endDate
                )
                
                if let days = components.day,
                    days >= 0 {
                    
                    let daysFormatted = "\(days)"
                    let daysAttributed = NSAttributedString(
                        string: daysFormatted,
                        attributes: [
                            .foregroundColor: Theme.Colors.accentColor
                        ]
                    )
                    
                    attributedDaysRemaining = LocalizedAtrributed(
                        .days_to_go,
                        attributes: [
                            .foregroundColor: Theme.Colors.textOnContentBackgroundColor
                        ],
                        replace: [
                            .days_to_go_replace_days: daysAttributed
                        ]
                    )
                } else {
                    attributedDaysRemaining = LocalizedAtrributed(
                        .ended,
                        attributes: [
                            .foregroundColor: Theme.Colors.textOnContentBackgroundColor
                        ],
                        replace: [:]
                    )
                }
            }
            
            return (attributedDaysRemaining, isUpcomming)
        }
        
        private func createOverviewTabViewModel(
            sale: Model.OverviewTab.Model
            ) -> OverviewTab.ViewModel {
            
            let name = sale.name
            let asset = sale.asset
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = self.verticalSpacing
            let attributedDescription = NSAttributedString(
                string: sale.description,
                attributes: [
                    .paragraphStyle: paragraphStyle
                ]
            )
            
            let saleName = "\(name) (\(asset))"
            let investedAmountFormatted = self.investedAmountFormatter.formatAmount(
                sale.investmentAmount,
                currency: sale.investmentAsset
            )
            let investedAmountFormattedAttributed = NSAttributedString(
                string: investedAmountFormatted,
                attributes: [
                    .foregroundColor: Theme.Colors.accentColor
                ]
            )
            
            let attributedInvetsedAmount = LocalizedAtrributed(
                .invested,
                attributes: [
                    .foregroundColor: Theme.Colors.textOnContentBackgroundColor
                ],
                replace: [
                    .invested_replace_amount: investedAmountFormattedAttributed
                ]
            )
            
            let investedPercentage = sale.investmentPercentage
            let investedPercentageRounded = Int(roundf(investedPercentage * 100))
            let investedPercentageText = "\(investedPercentageRounded)%"
            let attributedInvestedPercentageText = NSAttributedString(
                string: investedPercentageText,
                attributes: [
                    .foregroundColor: Theme.Colors.accentColor
                ]
            )
            
            let attributedInvestedPercentage = LocalizedAtrributed(
                .percent_funded,
                attributes: [
                    .foregroundColor: Theme.Colors.textOnContentBackgroundColor
                ],
                replace: [
                    .percent_funded_replace_percent: attributedInvestedPercentageText
                ]
            )
            
            let timeText = self.getTimeText(sale: sale)
            
            let overviewContent = self.clearEscapedCharacters(sale.overviewContent)
            
            return OverviewTab.ViewModel(
                imageUrl: sale.imageUrl,
                name: saleName,
                description: attributedDescription,
                youtubeVideoUrl: sale.youtubeVideoUrl,
                investedAmountText: attributedInvetsedAmount,
                investedPercentage: sale.investmentPercentage,
                investedPercentageText: attributedInvestedPercentage,
                timeText: timeText.timeText,
                overviewContent: overviewContent,
                identifier: sale.tabIdentifier
            )
        }
        
        private func createChartTabViewModel(
            tabModel: Model.ChartTabModel
            ) -> ChartTab.ViewModel {
            
            let formattedAmount = self.amountFormatter.formatAmount(
                tabModel.investedAmount,
                currency: tabModel.asset
            )
            var deployed = Localized(.deployed)
            if let deployedDate = tabModel.investedDate {
                let formattedDate = self.dateFormatter.dateToString(deployedDate)
                deployed.append(" \(formattedDate)")
            }
            
            let datePickerItems = tabModel.datePickerItems.map { (period) -> Model.PeriodViewModel in
                let title = self.titleForPeriod(period)
                return Model.PeriodViewModel(
                    title: title,
                    isEnabled: true,
                    period: period
                )
            }
            
            let formattedGrowth = self.getFormattedGrowthAmount(
                tabModel.growth,
                asset: tabModel.asset
            )
            var formattedGrowthSinceDate = ""
            if let selectedPeriod = tabModel.growthSincePeriod {
                let period = self.titleForPeriod(selectedPeriod).lowercased()
                formattedGrowthSinceDate = Localized(
                    .since_last_period,
                    replace: [
                        .since_last_period_replace_period: period
                    ]
                )
            }
            
            let chartViewModel = self.getChartViewModel(tabModel.chartModel, asset: tabModel.asset)
            
            return ChartTab.ViewModel(
                title: formattedAmount,
                subTitle: deployed,
                datePickerItems: datePickerItems,
                selectedDatePickerItemIndex: tabModel.selectedDatePickerItem ?? 0,
                growth: formattedGrowth,
                growthPositive: tabModel.growthPositive,
                growthSinceDate: formattedGrowthSinceDate,
                axisFormatters: self.setupAxisFormatters(
                    periods: tabModel.datePickerItems,
                    selectedPeriodIndex: tabModel.selectedDatePickerItem
                ),
                chartViewModel: chartViewModel,
                identifier: tabModel.tabIdentifier
            )
        }
        
        private func createEmptyTabViewModel(
            model: Model.EmptyTabModel
            ) -> EmptyContent.ViewModel {
            
            let message = model.message
            
            return EmptyContent.ViewModel(message: message)
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
        
        private func createInvestTabViewModel(
            tabModel: Model.InvestTabModel
            ) -> InvestTab.ViewModel {
            
            let availableAmount: String
            if let selectedAsset = tabModel.selectedBalance {
                let formatted = self.investedAmountFormatter.formatAmount(
                    tabModel.availableAmount,
                    currency: selectedAsset.asset
                )
                availableAmount = Localized(
                    .available_date,
                    replace: [
                        .available_date_replace_formatted: formatted
                    ]
                )
            } else {
                availableAmount = ""
            }
            
            return InvestTab.ViewModel(
                availableAmount: availableAmount,
                inputAmount: tabModel.amount,
                maxInputAmount: tabModel.availableAmount,
                selectedAsset: tabModel.selectedBalance?.asset,
                isCancellable: tabModel.isCancellable,
                actionTitle: tabModel.actionTitle,
                identifier: tabModel.tabIdentifier
            )
        }
        
        private func getBalanceDetailsViewModel(
            _ balanceDetails: Model.BalanceDetails?
            ) -> Model.BalanceDetailsViewModel? {
            
            guard let balanceDetails = balanceDetails else {
                return nil
            }
            
            let viewModel = Model.BalanceDetailsViewModel(
                asset: balanceDetails.asset,
                balance: self.amountFormatter.formatAmount(
                    balanceDetails.balance,
                    currency: balanceDetails.asset
                ),
                balanceId: balanceDetails.balanceId
            )
            return viewModel
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
        
        private func getChartViewModel(
            _ chartModel: Model.ChartModel,
            asset: String
            ) -> Model.ChartViewModel {
            
            let chartEntries = chartModel.entries.map { (chartEntry) -> Model.ChartDataEntry in
                return Model.ChartDataEntry(
                    x: chartEntry.date.timeIntervalSince1970,
                    y: (chartEntry.value as NSDecimalNumber).doubleValue
                )
            }
            
            let chartViewModel = Model.ChartViewModel(
                entries: chartEntries,
                maxValue: (chartModel.maxValue as NSDecimalNumber).doubleValue,
                formattedMaxValue: self.amountFormatter.formatAmount(
                    chartModel.maxValue,
                    currency: asset
                )
            )
            
            return chartViewModel
        }
        
        private func getTabContentType(tabType: Model.TabType) -> Model.TabContentType {
            switch tabType {
                
            case .invest(let investTabModel):
                let content = self.createInvestTabViewModel(tabModel: investTabModel)
                return .invest(content)
                
            case .chart(let chartTabModel):
                let content = self.createChartTabViewModel(tabModel: chartTabModel)
                return .chart(content)
                
            case .overview(let overviewTabModel):
                let content = self.createOverviewTabViewModel(sale: overviewTabModel)
                return .overview(content)
                
            case .empty(let emptyTabModel):
                let content = self.createEmptyTabViewModel(model: emptyTabModel)
                return .empty(content)
            }
        }
        
        private func clearEscapedCharacters(_ string: String?) -> String? {
            return string?
                .replacingOccurrences(of: "\\n", with: "\n")
                .replacingOccurrences(of: "\"", with: "")
                .replacingOccurrences(of: "\\'", with: "\'")
                .replacingOccurrences(of: "\\t", with: "\t")
                .replacingOccurrences(of: "\\\\", with: "\\")
        }
    }
}

extension SaleDetails.Presenter: SaleDetails.PresentationLogic {
    
    func presentTabsUpdated(response: Event.TabsUpdated.Response) {
        let tabContent = self.getTabContentType(tabType: response.selectedTabType)
        
        let viewModel = Event.TabsUpdated.ViewModel(
            tabs: response.tabs,
            selectedTabIndex: response.selectedTabIndex,
            selectedTabContent: tabContent
        )
        
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayTabsUpdated(viewModel: viewModel)
        }
    }
    
    func presentSelectBalance(response: Event.SelectBalance.Response) {
        let balanceViewModels: [Model.BalanceDetailsViewModel] =
            response.balances.compactMap({ balanceDetails in
                return self.getBalanceDetailsViewModel(balanceDetails)
            })
        let viewModel = Event.SelectBalance.ViewModel(balances: balanceViewModels)
        self.presenterDispatch.display { displayLogic in
            displayLogic.displaySelectBalance(viewModel: viewModel)
        }
    }
    
    func presentBalanceSelected(response: Event.BalanceSelected.Response) {
        let updatedTab = self.createInvestTabViewModel(tabModel: response.updatedTab)
        let viewModel = Event.BalanceSelected.ViewModel(updatedTab: updatedTab)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayBalanceSelected(viewModel: viewModel)
        }
    }
    
    func presentInvestAction(response: Event.InvestAction.Response) {
        let viewModel: Event.InvestAction.ViewModel
        switch response {
            
        case .failed(let error):
            viewModel = .failed(errorMessage: error.localizedDescription)
            
        case .loaded:
            viewModel = .loaded
            
        case .loading:
            viewModel = .loading
            
        case .succeeded(let saleInvestModel):
            viewModel = .succeeded(saleInvestModel)
        }
        
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayInvestAction(viewModel: viewModel)
        }
    }
    
    func presentCancelInvestAction(response: Event.CancelInvestAction.Response) {
        let viewModel: Event.CancelInvestAction.ViewModel
        switch response {
            
        case .failed(let error):
            viewModel = .failed(errorMessage: error.localizedDescription)
            
        case .succeeded:
            viewModel = .succeeded
            
        case .loading:
            viewModel = .loading
        }
        
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayCancelInvestAction(viewModel: viewModel)
        }
    }
    
    func presentSelectChartPeriod(response: Event.SelectChartPeriod.Response) {
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
        
        let chartViewModel = self.getChartViewModel(response.chartModel, asset: response.asset)
        let chartUpdatedViewModel = SaleDetails.ChartTab.ChartUpdatedViewModel(
            selectedPeriodIndex: response.selectedPeriodIndex ?? 0,
            growth: formattedGrowth,
            growthPositive: response.growthPositive,
            growthSinceDate: formattedGrowthSinceDate,
            axisFormatters: self.setupAxisFormatters(
                periods: response.periods,
                selectedPeriodIndex: response.selectedPeriodIndex
            ),
            chartViewModel: chartViewModel
        )
        let viewModel = Event.SelectChartPeriod.ViewModel(
            viewModel: chartUpdatedViewModel,
            updatedTab: self.createChartTabViewModel(tabModel: response.updatedTab)
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySelectChartPeriod(viewModel: viewModel)
        }
    }
    
    func presentSelectChartEntry(response: Event.SelectChartEntry.Response) {
        let formattedAmount = self.amountFormatter.formatAmount(
            response.investedAmount,
            currency: response.asset
        )
        var deployed = Localized(.deployed)
        if let deployedDate = response.investedDate {
            let formattedDate = self.dateFormatter.dateToString(deployedDate)
            deployed.append(" \(formattedDate)")
        }
        
        let chartEntrySelectedViewModel = SaleDetails.ChartTab.ChartEntrySelectedViewModel(
            title: formattedAmount,
            subTitle: deployed,
            identifier: response.identifier
        )
        let viewModel = Event.SelectChartEntry.ViewModel(viewModel: chartEntrySelectedViewModel)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySelectChartEntry(viewModel: viewModel)
        }
    }
    
    func presentTabWasSelected(response: Event.TabWasSelected.Response) {
        let tabContent = self.getTabContentType(tabType: response.tabType)
        let viewModel = Event.TabWasSelected.ViewModel(tabContent: tabContent)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayTabWasSelected(viewModel: viewModel)
        }
    }
}
