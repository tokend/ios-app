import Foundation
import Charts

protocol TradePresentationLogic {
    func presentViewDidLoadSync(response: Trade.Event.ViewDidLoadSync.Response)
    func presentPairsDidChange(response: Trade.Event.PairsDidChange.Response)
    func presentPairPriceDidChange(response: Trade.Event.PairPriceDidChange.Response)
    func presentLoading(response: Trade.Event.Loading.Response)
    func presentChartDidUpdate(response: Trade.Event.ChartDidUpdate.Response)
    func presentDidSelectPair(response: Trade.Event.DidSelectPair.Response)
    func presentSellOffersDidUpdate(response: Trade.Event.SellOffersDidUpdate.Response)
    func presentBuyOffersDidUpdate(response: Trade.Event.BuyOffersDidUpdate.Response)
    func presentCreateOffer(response: Trade.Event.CreateOffer.Response)
    func presentChartFormatterDidChange(response: Trade.Event.ChartFormatterDidChange.Response)
    func presentPeriodsDidChange(response: Trade.Event.PeriodsDidChange.Response)
    func presentError(response: Trade.Event.Error.Response)
}

extension Trade {
    typealias PresentationLogic = TradePresentationLogic
    
    class Presenter {
        
        private let presenterDispatch: PresenterDispatch
        private let amountFormatter: AmountFormatterProtocol
        private let dateFormatter: DateFormatterProtocol = TradeDateFormatter()
        
        init(
            amountFormatter: AmountFormatterProtocol,
            presenterDispatch: PresenterDispatch
            ) {
            
            self.amountFormatter = amountFormatter
            self.presenterDispatch = presenterDispatch
        }
        
        private func makePairViewModels(pairs: [Model.Pair]) -> [Trade.Model.PairViewModel] {
            return pairs.map { (pair) -> Trade.Model.PairViewModel in
                return pair.viewModel
            }
        }
        
        private func createBuyOffersDidUpdateViewModel(
            cells: [OrderBookTableViewCellModel<OrderBookTableViewBuyCell>]?
            ) -> Trade.Event.BuyOffersDidUpdate.ViewModel {
            
            if let cells = self.processCells(cells) {
                return .cells(cells)
            }
            return .empty
        }
        
        private func createSellOffersDidUpdateViewModel(
            cells: [OrderBookTableViewCellModel<OrderBookTableViewSellCell>]?
            ) -> Trade.Event.SellOffersDidUpdate.ViewModel {
            
            if let cells = self.processCells(cells) {
                return .cells(cells)
            }
            return .empty
        }
        
        private func processCells<CellType: OrderBookTableViewCell>(
            _ cells: [OrderBookTableViewCellModel<CellType>]?
            ) -> [OrderBookTableViewCellModel<CellType>]? {
            
            if let cells = cells {
                if cells.isEmpty {
                    return nil
                } else {
                    return cells
                }
            } else {
                return []
            }
        }
        
        private func setupAxisFormatters(
            periods: [Trade.Model.Period],
            selectedPeriodIndex: Int?
            ) -> Trade.Model.AxisFormatters {
            
            var period: Trade.Model.Period?
            if let selectedPeriodIndex = selectedPeriodIndex {
                period = periods[selectedPeriodIndex]
            }
            return Trade.Model.AxisFormatters(
                xAxisFormatter: {  [weak self] (value) -> String in
                    guard let strongSelf = self,
                        let period = period
                        else {
                            return ""
                    }
                    let date = Date(timeIntervalSince1970: value)
                    return strongSelf.dateFormatter.formatDateForXAxis(date, type: period)
                },
                yAxisFormatter: { (_) -> String in
                    return ""
            })
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
        
        private func periodsToViewModels(
            _ periods: [Model.Period]
            ) -> [Model.PeriodViewModel] {
            
            let periods = periods.map({ (period) -> Trade.Model.PeriodViewModel in
                return Trade.Model.PeriodViewModel(
                    title: self.titleForPeriod(period),
                    isEnabled: true,
                    period: period
                )
            })
            return periods
        }
    }
}

extension Trade.Presenter: Trade.PresentationLogic {
    func presentViewDidLoadSync(response: Trade.Event.ViewDidLoadSync.Response) {
        let pairs = self.makePairViewModels(pairs: response.pairs)
        
        let axisFormatters = self.setupAxisFormatters(
            periods: response.periods,
            selectedPeriodIndex: response.selectedPeriodIndex
        )
        
        let periods = self.periodsToViewModels(response.periods)
        
        let viewModel = Trade.Event.ViewDidLoadSync.ViewModel(
            pairs: pairs,
            selectedPairIndex: response.selectedPairIndex,
            selectedPeriodIndex: response.selectedPeriodIndex,
            base: response.base,
            quote: response.quote,
            periods: periods,
            axisFomatters: axisFormatters
        )
        self.presenterDispatch.displaySync { displayLogic in
            displayLogic.displayViewDidLoadSync(viewModel: viewModel)
        }
    }
    
    func presentPairsDidChange(response: Trade.Event.PairsDidChange.Response) {
        let pairs = self.makePairViewModels(pairs: response.pairs)
        let viewModel = Trade.Event.PairsDidChange.ViewModel(
            pairs: pairs,
            selectedPairIndex: response.selectedPairIndex
        )
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayPairsDidChange(viewModel: viewModel)
        }
    }
    
    func presentPairPriceDidChange(response: Trade.Event.PairPriceDidChange.Response) {
        let viewModel: Trade.Event.PairPriceDidChange.ViewModel
        if let price = response.price,
            let per = response.per {
            
            let priceString = self.amountFormatter.formatToken(price)
            var perString =  self.amountFormatter.formatToken(per)
            
            if let timestamp = response.timestamp {
                let date = self.dateFormatter.dateToString(timestamp)
                perString += Localized(
                    .at_date,
                    replace: [
                        .at_date_replace_date: date
                    ]
                )
            }
            
            viewModel = Trade.Event.PairPriceDidChange.ViewModel(
                price: priceString,
                per: perString
            )
        } else {
            viewModel = Trade.Event.PairPriceDidChange.ViewModel(price: nil, per: nil)
        }
        
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayPairPriceDidChange(viewModel: viewModel)
        }
    }
    
    func presentLoading(response: Trade.Event.Loading.Response) {
        let viewModel = Trade.Event.Loading.ViewModel(
            showForChart: response.showForChart,
            showForBuyTable: response.showForBuyTable,
            showForSellTable: response.showForSellTable,
            showForAssets: response.showForAssets
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayLoading(viewModel: viewModel)
        }
    }
    
    func presentChartDidUpdate(response: Trade.Event.ChartDidUpdate.Response) {
        let chartEntries = response.charts?.map({ (chart) -> ChartDataEntry in
            ChartDataEntry(
                x: chart.date.timeIntervalSince1970,
                y: (chart.value as NSDecimalNumber).doubleValue
            )
        })
        let viewModel = Trade.Event.ChartDidUpdate.ViewModel(
            chartEntries: chartEntries
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayChartDidUpdate(viewModel: viewModel)
        }
    }
    
    func presentDidSelectPair(response: Trade.Event.DidSelectPair.Response) {
        let viewModel = Trade.Event.DidSelectPair.ViewModel(
            base: response.base,
            quote: response.quote
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayDidSelectPair(viewModel: viewModel)
        }
    }
    
    func presentBuyOffersDidUpdate(response: Trade.Event.BuyOffersDidUpdate.Response) {
        let cells = response.offers?.map { (offer) -> OrderBookTableViewCellModel<OrderBookTableViewBuyCell> in
            return cellModelFrom(offer)
        }
        let viewModel: Trade.Event.BuyOffersDidUpdate.ViewModel = {
            return self.createBuyOffersDidUpdateViewModel(cells: cells)
        }()
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayBuyOffersDidUpdate(viewModel: viewModel)
        }
    }
    
    func presentSellOffersDidUpdate(response: Trade.Event.SellOffersDidUpdate.Response) {
        let cells = response.offers?.map { (offer) -> OrderBookTableViewCellModel<OrderBookTableViewSellCell> in
            return cellModelFrom(offer)
        }
        let viewModel: Trade.Event.SellOffersDidUpdate.ViewModel = {
            return self.createSellOffersDidUpdateViewModel(cells: cells)
        }()
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySellOffersDidUpdate(viewModel: viewModel)
        }
    }
    
    func presentCreateOffer(response: Trade.Event.CreateOffer.Response) {
        let viewModel = Trade.Event.CreateOffer.ViewModel(
            amount: response.amount,
            price: response.price,
            baseAsset: response.baseAsset,
            quoteAsset: response.quoteAsset
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayCreateOffer(viewModel: viewModel)
        }
    }
    
    private func cellModelFrom<CellType: OrderBookTableViewCell>(
        _ offer: Trade.Model.Offer
        ) -> OrderBookTableViewCellModel<CellType> {
        
        let anOffer = offer.getOffer(CellType.self)
        
        return OrderBookTableViewCellModel<CellType>(
            price: self.amountFormatter.formatTradeOrderToken(value: offer.price.value),
            priceCurrency: offer.price.currency,
            amount: self.amountFormatter.formatTradeOrderToken(value: offer.amount.value),
            amountCurrency: offer.amount.currency,
            isBuy: offer.isBuy,
            offer: anOffer,
            onClick: nil
        )
    }
    
    func presentChartFormatterDidChange(response: Trade.Event.ChartFormatterDidChange.Response) {
        let viewModel = Trade.Event.ChartFormatterDidChange.ViewModel(
            axisFormatters: Trade.Model.AxisFormatters(
                xAxisFormatter: { [weak self] (value) -> String in
                    guard let strongSelf = self else { return "" }
                    let date = Date(timeIntervalSince1970: value)
                    return strongSelf.dateFormatter.formatDateForXAxis(date, type: response.period)
                },
                yAxisFormatter: { (_) -> String in
                    return ""
            })
        )
        
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayChartFormatterDidChange(viewModel: viewModel)
        }
    }
    
    func presentPeriodsDidChange(response: Trade.Event.PeriodsDidChange.Response) {
        var periods = self.periodsToViewModels(response.periods)
        if periods.isEmpty {
            periods = [Trade.Model.PeriodViewModel(
                title: Localized(.no_available_periods),
                isEnabled: false,
                period: nil
                )]
        }
        let viewModel = Trade.Event.PeriodsDidChange.ViewModel(
            periods: periods,
            selectedPeriodIndex: response.selectedPeriodIndex
        )
        
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayPeriodsDidChange(viewModel: viewModel)
        }
    }
    
    func presentError(response: Trade.Event.Error.Response) {
        self.presenterDispatch.display { (displayLogic) in
            let viewModel = Trade.Event.Error.ViewModel(message: response.error.localizedDescription)
            displayLogic.displayError(viewModel: viewModel)
        }
    }
}

extension Trade.Model.Pair {
    fileprivate var viewModel: Trade.Model.PairViewModel {
        let base = self.base
        let quote = self.quote
        
        return Trade.Model.PairViewModel(
            title: "\(base)/\(quote)",
            id: self.id
        )
    }
}

extension Trade.Model.Offer {
    fileprivate func getOffer<CellType: OrderBookTableViewCell>(
        _ cellType: CellType.Type
        ) -> OrderBookTableViewCellModel<CellType>.Offer {
        
        return OrderBookTableViewCellModel<CellType>.Offer(
            amount: .init(
                value: self.amount.value,
                currency: self.amount.currency
            ),
            price: .init(
                value: self.price.value,
                currency: self.price.currency
            ),
            isBuy: self.isBuy
        )
    }
}
