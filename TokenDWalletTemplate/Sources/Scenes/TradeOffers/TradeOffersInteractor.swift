import Foundation
import RxCocoa
import RxSwift

public protocol TradeOffersBusinessLogic {
    typealias Event = TradeOffers.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onViewWillAppear(request: Event.ViewWillAppear.Request)
    func onContentTabSelected(request: Event.ContentTabSelected.Request)
    func onDidHighlightChart(request: Event.DidHighlightChart.Request)
    func onDidSelectPeriod(request: Event.DidSelectPeriod.Request)
    func onCreateOffer(request: Event.CreateOffer.Request)
}

extension TradeOffers {
    public typealias BusinessLogic = TradeOffersBusinessLogic
    
    @objc(TradeOffersInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = TradeOffers.Event
        public typealias Model = TradeOffers.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private var sceneModel: Model.SceneModel
        private let chartsFetcher: ChartsFetcherProtocol
        private let offersFetcher: OffersFetcherProtocol
        
        private var selectedPeriodIndex: Int? {
            guard let selectedPeriod = self.sceneModel.selectedPeriod else { return nil }
            return self.sceneModel.periods.index(of: selectedPeriod)
        }
        
        private var updatingOrderBook: Bool = false
        private var shouldUpdateOrderBook: Bool = true
        
        private var updatingCharts: Bool = false
        private var shouldUpdateCharts: Bool = true
        
        private var updatingTrades: Bool = false
        private var shouldUpdateTrades: Bool = true
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            sceneModel: Model.SceneModel,
            chartsFetcher: ChartsFetcherProtocol,
            offersFetcher: OffersFetcherProtocol
            ) {
            
            self.presenter = presenter
            self.sceneModel = sceneModel
            self.chartsFetcher = chartsFetcher
            self.offersFetcher = offersFetcher
        }
        
        // MARK: - Private
        
        private func updateScreenTitle() {
            let response = Event.ScreenTitleUpdated.Response(
                baseAsset: self.sceneModel.assetPair.baseAsset,
                quoteAsset: self.sceneModel.assetPair.quoteAsset,
                currentPrice: self.sceneModel.assetPair.currentPrice
            )
            self.presenter.presentScreenTitleUpdated(response: response)
        }
        
        private func getSelectedTabIndex() -> Int {
            return self.sceneModel.tabs.index(of: self.sceneModel.selectedTab) ?? 0
        }
        
        private func updatedSelectedContent(_ tab: Model.ContentTab) {
            self.sceneModel.selectedTab = tab
            
            let response = Event.ContentTabSelected.Response(selectedTab: self.sceneModel.selectedTab)
            self.presenter.presentContentTabSelected(response: response)
            
            switch tab {
                
            case .orderBook:
                self.updateOrderBook()
                
            case .chart:
                self.onChartsDidChange()
                self.updateCharts()
                
            case .trades:
                self.updateTrades()
            }
        }
        
        private func updateCharts() {
            guard self.shouldUpdateCharts && !self.updatingCharts else {
                return
            }
            
            self.onPriceDidChange()
            
            self.onLoading(showForChart: true)
            self.chartsFetcher.cancelRequests()
            let selectedPair = self.sceneModel.assetPair
            
            self.updatingCharts = true
            self.chartsFetcher.getChartsForBaseAsset(
                selectedPair.baseAsset,
                quoteAsset: selectedPair.quoteAsset
            ) { [weak self] (result) in
                
                self?.updatingCharts = false
                switch result {
                    
                case .success(let charts):
                    self?.shouldUpdateCharts = false
                    self?.sceneModel.charts = charts
                    self?.onChartsDidChange()
                    self?.onLoading(showForChart: false)
                    
                case .failure:
                    self?.shouldUpdateCharts = true
                    self?.onLoading(showForChart: false)
                }
            }
        }
        
        private func onPriceDidChange(_ price: Decimal? = nil, forTimestamp timestamp: Date? = nil) {
            let selectedAssetPair = self.sceneModel.assetPair
            
            let response = Event.PairPriceDidChange.Response(
                price: Model.Amount(
                    value: price ?? selectedAssetPair.currentPrice,
                    currency: selectedAssetPair.quoteAsset
                ),
                per: Model.Amount(
                    value: 1,
                    currency: selectedAssetPair.baseAsset
                ),
                timestamp: timestamp
            )
            
            self.presenter.presentPairPriceDidChange(response: response)
        }
        
        private func onChartsDidChange() {
            self.sceneModel.periods = Array((self.sceneModel.charts ?? [:]).keys)
                .sorted(by: { (left, right) -> Bool in
                    return left.weight < right.weight
                })
            self.onPeriodsDidChange()
            var periodCharts: [Model.Chart]?
            if let period = self.sceneModel.selectedPeriod {
                periodCharts = self.sceneModel.charts?[period]
            }
            self.chartsDidChange(periodCharts)
        }
        
        private func chartsDidChange(_ charts: [Model.Chart]?) {
            let response = Event.ChartDidUpdate.Response(charts: charts)
            self.presenter.presentChartDidUpdate(response: response)
        }
        
        private func onPeriodsDidChange() {
            if let oldSelectedPeriod = self.sceneModel.selectedPeriod,
                self.sceneModel.periods.contains(oldSelectedPeriod) {
                return
            }
            self.sceneModel.selectedPeriod = self.sceneModel.periods.first
            let response = Event.PeriodsDidChange.Response(
                periods: self.sceneModel.periods,
                selectedPeriodIndex: self.selectedPeriodIndex
            )
            self.presenter.presentPeriodsDidChange(response: response)
            if let period = self.sceneModel.selectedPeriod {
                self.selectPeriod(period)
            }
        }
        
        private func updateOrderBook() {
            guard self.shouldUpdateOrderBook && !self.updatingOrderBook else {
                return
            }
            
            self.sceneModel.buyOffers = nil
            self.sceneModel.sellOffers = nil
            self.onLoading(
                showForBuyTable: true,
                showForSellTable: true
            )
            self.onBuyOffersDidChange()
            self.onSellOffersDidChange()
            self.offersFetcher.cancelOffersRequests()
            
            let selectedPair = self.sceneModel.assetPair
            
            self.onLoading(
                showForBuyTable: false,
                showForSellTable: false
            )
            
            var updatingForBuy = true
            var updatedForBuy = false
            var updatingForSale = true
            var updatedForSale = false
            
            let checkUpdatingStates: () -> Void = { [weak self] in
                self?.updatingOrderBook = updatingForBuy || updatingForSale
                self?.shouldUpdateOrderBook = !(updatedForBuy && updatedForSale)
            }
            
            self.updatingOrderBook = true
            
            self.offersFetcher.getOffers(
                forBuy: true,
                base: selectedPair.baseAsset,
                quote: selectedPair.quoteAsset,
                limit: 20,
                cursor: nil,
                completion: { [weak self] (result) in
                    updatingForBuy = false
                    self?.onLoading(showForBuyTable: false)
                    
                    switch result {
                        
                    case .failed:
                        updatedForBuy = false
                        
                    case .succeeded(let offers):
                        updatedForBuy = true
                        self?.sceneModel.buyOffers = offers
                    }
                    
                    checkUpdatingStates()
                    
                    self?.onBuyOffersDidChange()
            })
            
            self.offersFetcher.getOffers(
                forBuy: false,
                base: selectedPair.baseAsset,
                quote: selectedPair.quoteAsset,
                limit: 20,
                cursor: nil,
                completion: { [weak self] (result) in
                    updatingForSale = false
                    self?.onLoading(showForSellTable: false)
                    
                    switch result {
                        
                    case .failed:
                        updatedForSale = false
                        
                    case .succeeded(let offers):
                        updatedForSale = true
                        self?.sceneModel.sellOffers = offers
                    }
                    
                    checkUpdatingStates()
                    
                    self?.onSellOffersDidChange()
            })
        }
        
        @discardableResult
        private func onBuyOffersDidChange() -> Bool {
            let offers = self.sceneModel.buyOffers
            let response = Event.BuyOffersDidUpdate.Response(offers: offers)
            self.presenter.presentBuyOffersDidUpdate(response: response)
            return offers != nil
        }
        
        @discardableResult
        private func onSellOffersDidChange() -> Bool {
            let offers = self.sceneModel.sellOffers
            let response = Event.SellOffersDidUpdate.Response(offers: offers)
            self.presenter.presentSellOffersDidUpdate(response: response)
            return offers != nil
        }
        
        private func updateTrades() {
            guard self.shouldUpdateTrades && !self.updatingTrades else {
                return
            }
            
            let selectedPair = self.sceneModel.assetPair
            
            self.onLoading(showForTrades: true)
            
            self.updatingTrades = true
            
            self.offersFetcher.getTrades(
                base: selectedPair.baseAsset,
                quote: selectedPair.quoteAsset,
                limit: 20,
                cursor: nil,
                completion: { [weak self] (result) in
                    self?.updatingTrades = false
                    self?.onLoading(showForTrades: false)
                    
                    switch result {
                        
                    case .failed(let error):
                        self?.shouldUpdateTrades = true
                        self?.onTradesDidChange(.error(error))
                        
                    case .succeeded(let trades):
                        self?.shouldUpdateTrades = false
                        self?.sceneModel.trades = trades
                        self?.onTradesDidChange(.trades(trades))
                    }
            })
        }
        
        private func onTradesDidChange(_ response: Event.TradesDidUpdate.Response) {
            self.presenter.presentTradesDidUpdate(response: response)
        }
        
        private func onLoading(
            showForChart: Bool? = nil,
            showForBuyTable: Bool? = nil,
            showForSellTable: Bool? = nil,
            showForTrades: Bool? = nil
            ) {
            
            let response = Event.Loading.Response(
                showForChart: showForChart,
                showForBuyTable: showForBuyTable,
                showForSellTable: showForSellTable,
                showForTrades: showForTrades
            )
            self.presenter.presentLoading(response: response)
        }
        
        private func selectPeriod(_ period: Model.Period) {
            self.sceneModel.selectedPeriod = period
            self.onChartsDidChange()
            
            let response = Event.ChartFormatterDidChange.Response(period: period)
            self.presenter.presentChartFormatterDidChange(response: response)
        }
    }
}

extension TradeOffers.Interactor: TradeOffers.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        self.updateScreenTitle()
        
        self.sceneModel.selectedTab = .orderBook
        let selectedIndex = self.getSelectedTabIndex()
        
        let response = Event.ViewDidLoad.Response(
            assetPair: self.sceneModel.assetPair,
            tabs: self.sceneModel.tabs,
            selectedIndex: selectedIndex,
            periods: self.sceneModel.periods,
            selectedPeriodIndex: self.selectedPeriodIndex
        )
        self.presenter.presentViewDidLoad(response: response)
        
        self.updatedSelectedContent(self.sceneModel.selectedTab)
    }
    
    public func onViewWillAppear(request: Event.ViewWillAppear.Request) {
        
    }
    
    public func onContentTabSelected(request: Event.ContentTabSelected.Request) {
        self.updatedSelectedContent(request.selectedTab)
    }
    
    public func onDidHighlightChart(request: Event.DidHighlightChart.Request) {
        guard let period = self.sceneModel.selectedPeriod,
            let charts = self.sceneModel.charts?[period]
            else {
                return
        }
        
        if let index = request.index {
            if index < charts.count {
                let chart = charts[index]
                self.onPriceDidChange(chart.value, forTimestamp: chart.date)
            } else {
                self.onPriceDidChange()
            }
        } else {
            self.onPriceDidChange()
        }
    }
    
    public func onDidSelectPeriod(request: Event.DidSelectPeriod.Request) {
        self.selectPeriod(request.period)
    }
    
    public func onCreateOffer(request: Event.CreateOffer.Request) {
        let selectedPair = self.sceneModel.assetPair
        
        let response = Event.CreateOffer.Response(
            amount: request.amount,
            price: request.price,
            baseAsset: selectedPair.baseAsset,
            quoteAsset: selectedPair.quoteAsset
        )
        self.presenter.presentCreateOffer(response: response)
    }
}

extension TradeOffers.Model.Period {
    fileprivate var weight: Int {
        switch self {
        case .hour:
            return 1
        case .day:
            return 2
        case .week:
            return 3
        case .month:
            return 4
        case .year:
            return 5
        }
    }
}
