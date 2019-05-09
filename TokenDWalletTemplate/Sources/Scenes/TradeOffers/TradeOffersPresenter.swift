import Foundation
import Charts

public protocol TradeOffersPresentationLogic {
    typealias Event = TradeOffers.Event
    
    func presentViewDidLoad(response: Event.ViewDidLoad.Response)
    func presentScreenTitleUpdated(response: Event.ScreenTitleUpdated.Response)
    func presentContentTabSelected(response: Event.ContentTabSelected.Response)
    func presentChartPeriodsDidChange(response: Event.ChartPeriodsDidChange.Response)
    func presentChartPairPriceDidChange(response: Event.ChartPairPriceDidChange.Response)
    func presentChartDidUpdate(response: Event.ChartDidUpdate.Response)
    func presentOffersDidUpdate(response: Event.OffersDidUpdate.Response)
    func presentTradesDidUpdate(response: Event.TradesDidUpdate.Response)
    func presentLoading(response: Event.Loading.Response)
    func presentChartFormatterDidChange(response: Event.ChartFormatterDidChange.Response)
    func presentCreateOffer(response: Event.CreateOffer.Response)
    func presentSwipeRecognized(response: Event.SwipeRecognized.Response)
}

extension TradeOffers {
    public typealias PresentationLogic = TradeOffersPresentationLogic
    
    @objc(TradeOffersPresenter)
    public class Presenter: NSObject {
        
        public typealias Event = TradeOffers.Event
        public typealias Model = TradeOffers.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        private let amountFormatter: AmountFormatterProtocol
        private let dateFormatter: DateFormatterProtocol
        
        // MARK: -
        
        public init(
            presenterDispatch: PresenterDispatch,
            amountFormatter: AmountFormatterProtocol,
            dateFormatter: DateFormatterProtocol
            ) {
            
            self.presenterDispatch = presenterDispatch
            self.amountFormatter = amountFormatter
            self.dateFormatter = dateFormatter
        }
        
        // MARK: - Private
        
        private func setupAxisFormatters(
            periods: [Model.Period],
            selectedPeriodIndex: Int?
            ) -> Model.AxisFormatters {
            
            var period: Model.Period?
            if let selectedPeriodIndex = selectedPeriodIndex {
                period = periods[selectedPeriodIndex]
            }
            return Model.AxisFormatters(
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
        
        private func getPeriodViewModels(
            _ periods: [Model.Period]
            ) -> [Model.PeriodViewModel] {
            
            let periods = periods.map({ (period) -> Model.PeriodViewModel in
                return Model.PeriodViewModel(
                    title: self.titleForPeriod(period),
                    isEnabled: true,
                    period: period
                )
            })
            return periods
        }
        
        private func cellModelFrom<CellType: OrderBookTableViewCell>(
            _ offer: Model.Offer,
            maxVolume: Decimal,
            isLoading: Bool
            ) -> OrderBookTableViewCellModel<CellType> {
            
            let anOffer = offer.getOffer(CellType.self)
            let volumeCoefficient = NSDecimalNumber(
                decimal: ((offer.volume)/maxVolume)
                ).doubleValue
            
            return OrderBookTableViewCellModel<CellType>(
                price: self.amountFormatter.formatTradeOrderToken(value: offer.price.value),
                priceCurrency: offer.price.currency,
                amount: self.amountFormatter.formatTradeOrderToken(value: offer.amount.value),
                amountCurrency: offer.amount.currency,
                coefficient: volumeCoefficient,
                isBuy: offer.isBuy,
                offer: anOffer,
                isLoading: isLoading,
                onClick: nil
            )
        }
        
        private func getTradeViewModel(
            _ trade: Model.Trade,
            isLoading: Bool
            ) -> Model.TradeViewModel {
            
            let price = self.amountFormatter.assetAmountToString(trade.price)
            let amount = self.amountFormatter.assetAmountToString(trade.amount)
            let time = self.dateFormatter.dateToString(trade.date, relative: true)
            let priceGrowth = trade.priceGrows
            
            return Model.TradeViewModel(
                price: price,
                amount: amount,
                time: time,
                priceGrowth: priceGrowth,
                isLoading: isLoading
            )
        }
    }
}

extension TradeOffers.Presenter: TradeOffers.PresentationLogic {
    public func presentViewDidLoad(response: Event.ViewDidLoad.Response) {
        let tabs = response.tabs.map { ($0.title, $0) }
        let periods = self.getPeriodViewModels(response.periods)
        let axisFomatters = self.setupAxisFormatters(
            periods: response.periods,
            selectedPeriodIndex: response.selectedPeriodIndex
        )
        
        let viewModel = Event.ViewDidLoad.ViewModel(
            assetPair: response.assetPair,
            tabs: tabs,
            selectedIndex: response.selectedIndex,
            periods: periods,
            selectedPeriodIndex: response.selectedPeriodIndex,
            axisFomatters: axisFomatters
        )
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayViewDidLoad(viewModel: viewModel)
        }
    }
    
    public func presentScreenTitleUpdated(response: Event.ScreenTitleUpdated.Response) {
        let screenTitle = "\(response.baseAsset)/\(response.quoteAsset)"
        let formattedPrice = self.amountFormatter.assetAmountToString(response.currentPrice)
        let screenSubTitle = "1 \(response.baseAsset) = \(formattedPrice) \(response.quoteAsset)"
        let viewModel = Event.ScreenTitleUpdated.ViewModel(
            screenTitle: screenTitle,
            screenSubTitle: screenSubTitle
        )
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayScreenTitleUpdated(viewModel: viewModel)
        }
    }
    
    public func presentContentTabSelected(response: Event.ContentTabSelected.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayContentTabSelected(viewModel: viewModel)
        }
    }
    
    public func presentChartPeriodsDidChange(response: Event.ChartPeriodsDidChange.Response) {
        var periods = self.getPeriodViewModels(response.periods)
        if periods.isEmpty {
            periods = [Model.PeriodViewModel(
                title: Localized(.no_available_periods),
                isEnabled: false,
                period: nil
                )]
        }
        let viewModel = Event.ChartPeriodsDidChange.ViewModel(
            periods: periods,
            selectedPeriodIndex: response.selectedPeriodIndex
        )
        
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayChartPeriodsDidChange(viewModel: viewModel)
        }
    }
    
    public func presentChartPairPriceDidChange(response: Event.ChartPairPriceDidChange.Response) {
        let viewModel: Event.ChartPairPriceDidChange.ViewModel
        if let price = response.price,
            let per = response.per {
            
            let priceString = self.amountFormatter.formatToken(price)
            var perString =  self.amountFormatter.formatToken(per)
            
            if let timestamp = response.timestamp {
                let date = self.dateFormatter.dateToString(timestamp, relative: false)
                perString += Localized(
                    .at_date,
                    replace: [
                        .at_date_replace_date: date
                    ]
                )
            }
            
            viewModel = Event.ChartPairPriceDidChange.ViewModel(
                price: priceString,
                per: perString
            )
        } else {
            viewModel = Event.ChartPairPriceDidChange.ViewModel(price: nil, per: nil)
        }
        
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayChartPairPriceDidChange(viewModel: viewModel)
        }
    }
    
    public func presentChartDidUpdate(response: Event.ChartDidUpdate.Response) {
        let viewModel: Event.ChartDidUpdate.ViewModel
        
        switch response {
            
        case .charts(let charts):
            let chartEntries = charts.map({ (chart) -> ChartDataEntry in
                ChartDataEntry(
                    x: chart.date.timeIntervalSince1970,
                    y: (chart.value as NSDecimalNumber).doubleValue
                )
            })
            viewModel = .charts(chartEntries)
            
        case .error(let error):
            viewModel = .error(error.localizedDescription)
        }
        
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayChartDidUpdate(viewModel: viewModel)
        }
    }
    
    public func presentOffersDidUpdate(response: Event.OffersDidUpdate.Response) {
        let viewModel: Event.OffersDidUpdate.ViewModel
        switch response {
            
        case .error(let error):
            viewModel = .error(error: error.localizedDescription)
            
        case .offers(let buy, let sell, let maxVolume):
            let buyCells = buy.map { (offer) -> OrderBookTableViewCellModel<OrderBookTableViewBuyCell> in
                return self.cellModelFrom(offer, maxVolume: maxVolume, isLoading: false)
            }
            let sellCells = sell.map { (offer) -> OrderBookTableViewCellModel<OrderBookTableViewSellCell> in
                return self.cellModelFrom(offer, maxVolume: maxVolume, isLoading: false)
            }
            viewModel = .cells(buy: buyCells, sell: sellCells)
        }
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayOffersDidUpdate(viewModel: viewModel)
        }
    }
    
    public func presentTradesDidUpdate(response: Event.TradesDidUpdate.Response) {
        let viewModel: Event.TradesDidUpdate.ViewModel
        
        switch response {
            
        case .error(let error):
            viewModel = .error(error.localizedDescription)
            
        case .trades(let trades, let hasMoreItems):
            var tradeViewModels = trades.map { (trade) -> Model.TradeViewModel in
                return self.getTradeViewModel(trade, isLoading: false)
            }
            if hasMoreItems, let anyTrade = trades.first {
                tradeViewModels.append(self.getTradeViewModel(anyTrade, isLoading: true))
            }
            viewModel = .trades(trades: tradeViewModels)
        }
        
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayTradesDidUpdate(viewModel: viewModel)
        }
    }
    
    public func presentLoading(response: Event.Loading.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayLoading(viewModel: viewModel)
        }
    }
    
    public func presentChartFormatterDidChange(response: Event.ChartFormatterDidChange.Response) {
        let viewModel = Event.ChartFormatterDidChange.ViewModel(
            axisFormatters: Model.AxisFormatters(
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
    
    public func presentCreateOffer(response: Event.CreateOffer.Response) {
        let viewModel = Event.CreateOffer.ViewModel(
            amount: response.amount,
            price: response.price,
            baseAsset: response.baseAsset,
            quoteAsset: response.quoteAsset
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayCreateOffer(viewModel: viewModel)
        }
    }
    
    public func presentSwipeRecognized(response: Event.SwipeRecognized.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySwipeRecognized(viewModel: viewModel)
        }
    }
}

extension TradeOffers.Model.ContentTab {
    
    fileprivate var title: String {
        switch self {
        case .orderBook:
            return Localized(.order_book_cap)
        case .chart:
            return Localized(.chart_cap)
        case .trades:
            return Localized(.trades_cap)
        }
    }
}

extension TradeOffers.Model.Offer {
    
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
