import Foundation
import Charts

public protocol TradeOffersPresentationLogic {
    typealias Event = TradeOffers.Event
    
    func presentViewDidLoad(response: Event.ViewDidLoad.Response)
    func presentScreenTitleUpdated(response: Event.ScreenTitleUpdated.Response)
    func presentContentTabSelected(response: Event.ContentTabSelected.Response)
    func presentPeriodsDidChange(response: Event.PeriodsDidChange.Response)
    func presentPairPriceDidChange(response: Event.PairPriceDidChange.Response)
    func presentChartDidUpdate(response: Event.ChartDidUpdate.Response)
    func presentSellOffersDidUpdate(response: Event.SellOffersDidUpdate.Response)
    func presentBuyOffersDidUpdate(response: Event.BuyOffersDidUpdate.Response)
    func presentTradesDidUpdate(response: Event.TradesDidUpdate.Response)
    func presentLoading(response: Event.Loading.Response)
    func presentChartFormatterDidChange(response: Event.ChartFormatterDidChange.Response)
    func presentError(response: Event.Error.Response)
    func presentCreateOffer(response: Event.CreateOffer.Response)
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
        
        private func createBuyOffersDidUpdateViewModel(
            cells: [OrderBookTableViewCellModel<OrderBookTableViewBuyCell>]?
            ) -> Event.BuyOffersDidUpdate.ViewModel {
            
            if let cells = self.processCells(cells) {
                return .cells(cells)
            }
            return .empty
        }
        
        private func createSellOffersDidUpdateViewModel(
            cells: [OrderBookTableViewCellModel<OrderBookTableViewSellCell>]?
            ) -> Event.SellOffersDidUpdate.ViewModel {
            
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
            _ offer: Model.Offer
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
        
        private func getTradeViewModels(_ trades: [Model.Trade]) -> [Model.TradeViewModel] {
            return trades.map({ (trade) -> Model.TradeViewModel in
                let price = self.amountFormatter.assetAmountToString(trade.price)
                let amount = self.amountFormatter.assetAmountToString(trade.amount)
                let time = self.dateFormatter.dateToString(trade.date)
                let priceGrowth = trade.priceGrows
                
                return Model.TradeViewModel(
                    price: price,
                    amount: amount,
                    time: time,
                    priceGrowth: priceGrowth
                )
            })
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
    
    public func presentPeriodsDidChange(response: Event.PeriodsDidChange.Response) {
        var periods = self.getPeriodViewModels(response.periods)
        if periods.isEmpty {
            periods = [Model.PeriodViewModel(
                title: Localized(.no_available_periods),
                isEnabled: false,
                period: nil
                )]
        }
        let viewModel = Event.PeriodsDidChange.ViewModel(
            periods: periods,
            selectedPeriodIndex: response.selectedPeriodIndex
        )
        
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayPeriodsDidChange(viewModel: viewModel)
        }
    }
    
    public func presentPairPriceDidChange(response: Event.PairPriceDidChange.Response) {
        let viewModel: Event.PairPriceDidChange.ViewModel
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
            
            viewModel = Event.PairPriceDidChange.ViewModel(
                price: priceString,
                per: perString
            )
        } else {
            viewModel = Event.PairPriceDidChange.ViewModel(price: nil, per: nil)
        }
        
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayPairPriceDidChange(viewModel: viewModel)
        }
    }
    
    public func presentChartDidUpdate(response: Event.ChartDidUpdate.Response) {
        let chartEntries = response.charts?.map({ (chart) -> ChartDataEntry in
            ChartDataEntry(
                x: chart.date.timeIntervalSince1970,
                y: (chart.value as NSDecimalNumber).doubleValue
            )
        })
        let viewModel = Event.ChartDidUpdate.ViewModel(
            chartEntries: chartEntries
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayChartDidUpdate(viewModel: viewModel)
        }
    }
    
    public func presentSellOffersDidUpdate(response: Event.SellOffersDidUpdate.Response) {
        let cells = response.offers?.map { (offer) -> OrderBookTableViewCellModel<OrderBookTableViewSellCell> in
            return self.cellModelFrom(offer)
        }
        let viewModel: Event.SellOffersDidUpdate.ViewModel = {
            return self.createSellOffersDidUpdateViewModel(cells: cells)
        }()
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySellOffersDidUpdate(viewModel: viewModel)
        }
    }
    
    public func presentBuyOffersDidUpdate(response: Event.BuyOffersDidUpdate.Response) {
        let cells = response.offers?.map { (offer) -> OrderBookTableViewCellModel<OrderBookTableViewBuyCell> in
            return self.cellModelFrom(offer)
        }
        let viewModel: Event.BuyOffersDidUpdate.ViewModel = {
            return self.createBuyOffersDidUpdateViewModel(cells: cells)
        }()
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayBuyOffersDidUpdate(viewModel: viewModel)
        }
    }
    
    public func presentTradesDidUpdate(response: Event.TradesDidUpdate.Response) {
        let viewModel: Event.TradesDidUpdate.ViewModel
        
        switch response {
            
        case .error(let error):
            viewModel = .error(error.localizedDescription)
            
        case .trades(let trades):
            viewModel = .trades(self.getTradeViewModels(trades))
        }
        
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayTradesDidUpdate(viewModel: viewModel)
        }
    }
    
    public func presentLoading(response: Event.Loading.Response) {
        let viewModel = Event.Loading.ViewModel(
            showForChart: response.showForChart,
            showForBuyTable: response.showForBuyTable,
            showForSellTable: response.showForSellTable,
            showForTrades: response.showForTrades
        )
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
    
    public func presentError(response: Event.Error.Response) {
        let viewModel = Event.Error.ViewModel(message: response.error.localizedDescription)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayError(viewModel: viewModel)
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
