import Foundation

protocol SaleDetailsPresentationLogic {
    typealias Event = SaleDetails.Event
    
    func presentSectionsUpdated(response: Event.SectionsUpdated.Response)
    func presentSelectBalance(response: Event.SelectBalance.Response)
    func presentBalanceSelected(response: Event.BalanceSelected.Response)
    func presentInvestAction(response: Event.InvestAction.Response)
    func presentDidSelectMoreInfoButton(response: Event.DidSelectMoreInfoButton.Response)
    func presentSelectChartPeriod(response: Event.SelectChartPeriod.Response)
    func presentSelectChartEntry(response: Event.SelectChartEntry.Response)
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
        
        // MARK: -
        
        init(
            presenterDispatch: PresenterDispatch,
            amountFormatter: AmountFormatterProtocol,
            dateFormatter: DateFormatterProtocol,
            chartDateFormatter: ChartDateFormatterProtocol,
            investedAmountFormatter: InvestedAmountFormatter
            ) {
            
            self.presenterDispatch = presenterDispatch
            self.amountFormatter = amountFormatter
            self.dateFormatter = dateFormatter
            self.chartDateFormatter = chartDateFormatter
            self.investedAmountFormatter = investedAmountFormatter
        }
        
        // MARK: - Private
        
        private func getTimeText(sale: Model.DescriptionCellModel) -> (timeText: String, isUpcomming: Bool) {
            let daysRemaining: String
            let isUpcomming: Bool
            
            if sale.startDate > Date() {
                let components = Calendar.current.dateComponents(
                    [Calendar.Component.day],
                    from: Date(),
                    to: sale.startDate
                )
                
                let days = components.day ?? 0
                let startsInString = Localized(
                    .days_days,
                    replace: [
                        .days_days_replace_days: days
                    ]
                )
                
                isUpcomming = true
                
                daysRemaining = [Localized(.starts_in), startsInString].joined()
            } else {
                isUpcomming = false
                
                let components = Calendar.current.dateComponents(
                    [Calendar.Component.day],
                    from: Date(),
                    to: sale.endDate
                )
                
                if let days = components.day,
                    days >= 0 {
                    let daysRemainingString = Localized(
                        .days_days,
                        replace: [
                            .days_days_replace_days: days
                        ]
                    )
                    daysRemaining = [daysRemainingString, Localized(.left_lowercased)].joined()
                } else {
                    daysRemaining = Localized(.ended)
                }
            }
            
            return (daysRemaining, isUpcomming)
        }
        
        private func createDescriptionSectionViewModel(
            sale: Model.DescriptionCellModel
            ) -> DescriptionCell.ViewModel {
            
            let name = sale.name
            let asset = sale.asset
            let saleName = "\(name) (\(asset))"
            let investedAmountFormatted = self.investedAmountFormatter.formatAmount(
                sale.investmentAmount,
                currency: sale.investmentAsset
            )
            let investedAmount = Localized(
                .invested,
                replace: [
                    .invested_replace_amount: investedAmountFormatted
                ]
            )

            let investedPercentage = sale.investmentPercentage
            let investedPercentageRounded = Int(roundf(investedPercentage * 100))
            let investedPercentageText = "\(investedPercentageRounded)%"
            let investorsCount = sale.investorsCount
            let investorsText = Localized(
                .investors,
                replace: [
                    .investors_replace_count: investorsCount
                ]
            )

            let timeText = self.getTimeText(sale: sale)
            
            return DescriptionCell.ViewModel(
                imageUrl: sale.imageUrl,
                name: saleName,
                description: sale.description,
                youtubeVideoUrl: sale.youtubeVideoUrl,
                investedAmountText: investedAmount,
                investedPercentage: sale.investmentPercentage,
                investedPercentageText: investedPercentageText,
                investorsText: investorsText,
                timeText: timeText.timeText,
                identifier: sale.cellIdentifier
            )
        }
        
        private func createChartSectionViewModel(
            cellModel: Model.ChartCellModel
            ) -> ChartCell.ViewModel {
            
            let formattedAmount = self.amountFormatter.formatAmount(
                cellModel.investedAmount,
                currency: cellModel.asset
            )
            var deployed = Localized(.deployed)
            if let deployedDate = cellModel.investedDate {
                let formattedDate = self.dateFormatter.dateToString(deployedDate)
                deployed.append(" \(formattedDate)")
            }
            
            let datePickerItems = cellModel.datePickerItems.map { (period) -> Model.PeriodViewModel in
                let title = self.titleForPeriod(period)
                return Model.PeriodViewModel(
                    title: title,
                    isEnabled: true,
                    period: period
                )
            }
            
            let formattedGrowth = self.getFormattedGrowthAmount(
                cellModel.growth,
                asset: cellModel.asset
            )
            var formattedGrowthSinceDate = ""
            if let selectedPeriod = cellModel.growthSincePeriod {
                let period = self.titleForPeriod(selectedPeriod).lowercased()
                formattedGrowthSinceDate = Localized(
                    .since_last_period,
                    replace: [
                        .since_last_period_replace_period: period
                    ]
                )
            }
            
            let chartViewModel = self.getChartViewModel(cellModel.chartModel, asset: cellModel.asset)
            
            return ChartCell.ViewModel(
                title: formattedAmount,
                subTitle: deployed,
                datePickerItems: datePickerItems,
                selectedDatePickerItemIndex: cellModel.selectedDatePickerItem ?? 0,
                growth: formattedGrowth,
                growthPositive: cellModel.growthPositive,
                growthSinceDate: formattedGrowthSinceDate,
                axisFormatters: self.setupAxisFormatters(
                    periods: cellModel.datePickerItems,
                    selectedPeriodIndex: cellModel.selectedDatePickerItem
                ),
                chartViewModel: chartViewModel,
                identifier: cellModel.cellIdentifier
            )
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
        
        private func createInvestingSectionViewModel(
            cellModel: Model.InvestingCellModel
            ) -> InvestingCell.ViewModel {
            
            let availableAmount: String
            if let selectedAsset = cellModel.selectedBalance {
                let formatted = self.investedAmountFormatter.formatAmount(
                    cellModel.availableAmount,
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
            
            return InvestingCell.ViewModel(
                availableAmount: availableAmount,
                inputAmount: cellModel.amount,
                maxInputAmount: cellModel.availableAmount,
                selectedAsset: cellModel.selectedBalance?.asset,
                identifier: cellModel.cellIdentifier
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
    }
}

extension SaleDetails.Presenter: SaleDetails.PresentationLogic {
    func presentSectionsUpdated(response: Event.SectionsUpdated.Response) {
        let sectionsViewModel = response.sections.map { (sectionModel) -> Model.SectionViewModel in
            return Model.SectionViewModel(cells: sectionModel.cells.map({ (cellModel) -> CellViewAnyModel in
                
                switch cellModel.cellType {
                    
                case .description(let descriptionCellModel):
                    return self.createDescriptionSectionViewModel(sale: descriptionCellModel)
                    
                case .investing(let investingCellModel):
                    return self.createInvestingSectionViewModel(cellModel: investingCellModel)
                    
                case .chart(let chartCellModel):
                    return self.createChartSectionViewModel(cellModel: chartCellModel)
                }
            }))
        }
        
        let viewModel = Event.SectionsUpdated.ViewModel(sections: sectionsViewModel)
        
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySectionsUpdated(viewModel: viewModel)
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
        let updatedCell = self.createInvestingSectionViewModel(cellModel: response.updatedCell)
        let viewModel = Event.BalanceSelected.ViewModel(updatedCell: updatedCell)
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
    
    func presentDidSelectMoreInfoButton(response: Event.DidSelectMoreInfoButton.Response) {
        let viewModel = Event.DidSelectMoreInfoButton.ViewModel(
            saleId: response.saleId,
            blobId: response.blobId,
            asset: response.asset
        )
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayDidSelectMoreInfoButton(viewModel: viewModel)
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
        
        let chartUpdatedViewModel = SaleDetails.ChartCell.ChartUpdatedViewModel(
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
            updatedCell: self.createChartSectionViewModel(cellModel: response.updatedCell)
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
        
        let chartEntrySelectedViewModel = SaleDetails.ChartCell.ChartEntrySelectedViewModel(
            title: formattedAmount,
            subTitle: deployed,
            identifier: response.identifier
        )
        let viewModel = Event.SelectChartEntry.ViewModel(viewModel: chartEntrySelectedViewModel)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySelectChartEntry(viewModel: viewModel)
        }
    }
}
