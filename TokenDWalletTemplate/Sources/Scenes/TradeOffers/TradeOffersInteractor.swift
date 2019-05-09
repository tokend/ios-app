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
    func onPullToRefresh(request: Event.PullToRefresh.Request)
    func onLoadMore(request: Event.LoadMore.Request)
    func onSwipeRecognized(request: Event.SwipeRecognized.Request)
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
        private let offersFetcher: OffersFetcherProtocol
        private let chartsFetcher: ChartsFetcherProtocol
        private let tradesFetcher: TradesFetcherProtocol
        
        private var selectedTabIndex: Int? {
            return self.sceneModel.tabs.index(of: self.sceneModel.selectedTab)
        }
        
        private var selectedPeriodIndex: Int? {
            guard let selectedPeriod = self.sceneModel.selectedPeriod else { return nil }
            return self.sceneModel.periods.index(of: selectedPeriod)
        }
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            sceneModel: Model.SceneModel,
            offersFetcher: OffersFetcherProtocol,
            chartsFetcher: ChartsFetcherProtocol,
            tradesFetcher: TradesFetcherProtocol
            ) {
            
            self.presenter = presenter
            self.sceneModel = sceneModel
            self.offersFetcher = offersFetcher
            self.chartsFetcher = chartsFetcher
            self.tradesFetcher = tradesFetcher
        }
        
        // MARK: - Private
        
        private func loadCharts() {
            let baseAsset = self.sceneModel.assetPair.baseAsset
            let quoteAsset = self.sceneModel.assetPair.quoteAsset
            
            let response = Event.Loading.Response(
                isLoading: true,
                content: .chart
            )
            self.presenter.presentLoading(response: response)
            
            self.chartsFetcher.getChartsForBaseAsset(
                baseAsset,
                quoteAsset: quoteAsset,
                completion: { [weak self] (result) in
                    let response = Event.Loading.Response(
                        isLoading: false,
                        content: .chart
                    )
                    self?.presenter.presentLoading(response: response)
                    
                    switch result {
                        
                    case .failure(let error):
                        let response = Event.ChartDidUpdate.Response.error(error)
                        self?.presenter.presentChartDidUpdate(response: response)
                        
                    case .success(let charts):
                        self?.sceneModel.charts = charts
                        self?.onChartsDidChange()
                    }
            })
        }
        
        private func observeTrades(pageSize: Int) {
            self.tradesFetcher.observeErrorStatus()
                .subscribe(onNext: { [weak self] (error) in
                    let response = Event.TradesDidUpdate.Response.error(error)
                    self?.presenter.presentTradesDidUpdate(response: response)
                })
                .disposed(by: self.disposeBag)
            
            self.tradesFetcher.observeLoadingStatus()
                .subscribe(onNext: { [weak self] (status) in
                    let response = Event.Loading.Response(
                        isLoading: status == .loading,
                        content: .trades
                    )
                    self?.presenter.presentLoading(response: response)
                })
                .disposed(by: self.disposeBag)
            
            self.tradesFetcher.observeItems(pageSize: pageSize)
                .subscribe(onNext: { [weak self] (trades) in
                    self?.sceneModel.trades = trades
                    self?.onTradesDidUpdate()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeOffers(pageSize: Int) {
            self.offersFetcher.observeErrorStatus()
                .subscribe(onNext: { [weak self] (error) in
                    let response = Event.OffersDidUpdate.Response.error(error: error)
                    self?.presenter.presentOffersDidUpdate(response: response)
                })
                .disposed(by: self.disposeBag)
            
            self.offersFetcher.observeLoadingStatus()
                .subscribe(onNext: { [weak self] (status) in
                    let response = Event.Loading.Response(
                        isLoading: status == .loading,
                        content: .orderBook
                    )
                    self?.presenter.presentLoading(response: response)
                })
                .disposed(by: self.disposeBag)
            
            self.offersFetcher.observeOrderBook(pageSize: pageSize)
                .subscribe(onNext: { [weak self] (orderBook) in
                    self?.sceneModel.orderBook = orderBook
                    
                    self?.onOffersDidUpdate()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func updateScreenTitle() {
            let response = Event.ScreenTitleUpdated.Response(
                baseAsset: self.sceneModel.assetPair.baseAsset,
                quoteAsset: self.sceneModel.assetPair.quoteAsset,
                currentPrice: self.sceneModel.assetPair.currentPrice
            )
            self.presenter.presentScreenTitleUpdated(response: response)
        }
        
        private func updatedSelectedContent(_ tab: Model.ContentTab) {
            self.sceneModel.selectedTab = tab
            
            switch tab {
                
            case .orderBook:
                break
                
            case .chart:
                if self.sceneModel.charts?.isEmpty ?? true {
                    self.loadCharts()
                }
                
            case .trades:
                break
            }
            
            let response = Event.ContentTabSelected.Response(selectedTab: self.sceneModel.selectedTab)
            self.presenter.presentContentTabSelected(response: response)
        }
        
        private func onOffersDidUpdate() {
            let response = Event.OffersDidUpdate.Response.offers(
                buy: self.sceneModel.orderBook.buyItems,
                sell: self.sceneModel.orderBook.sellItems,
                maxVolume: self.sceneModel.orderBook.maxVolume
            )
            self.presenter.presentOffersDidUpdate(response: response)
        }
        
        private func onChartsDidChange() {
            self.sceneModel.periods = self.sceneModel.charts?.keys.sorted() ?? []
            self.onChartPriceDidChange()
            self.onChartPeriodsDidChange()
            
            let periodCharts: [Model.Chart]
            if let period = self.sceneModel.selectedPeriod {
                periodCharts = self.sceneModel.charts?[period] ?? []
            } else {
                periodCharts = []
            }
            
            let response = Event.ChartDidUpdate.Response.charts(periodCharts)
            self.presenter.presentChartDidUpdate(response: response)
        }
        
        private func updateSelectedPeriod(_ period: Model.Period) {
            self.sceneModel.selectedPeriod = period
            self.onChartsDidChange()
            
            let response = Event.ChartFormatterDidChange.Response(period: period)
            self.presenter.presentChartFormatterDidChange(response: response)
        }
        
        private func onChartPeriodsDidChange() {
            var shouldUpdateSelectedPeriod = false
            if let oldSelectedPeriod = self.sceneModel.selectedPeriod,
                !self.sceneModel.periods.contains(oldSelectedPeriod) {
                self.sceneModel.selectedPeriod = self.sceneModel.periods.first
                shouldUpdateSelectedPeriod = true
            }
            
            let response = Event.ChartPeriodsDidChange.Response(
                periods: self.sceneModel.periods,
                selectedPeriodIndex: self.selectedPeriodIndex
            )
            self.presenter.presentChartPeriodsDidChange(response: response)
            
            if shouldUpdateSelectedPeriod, let selectedPeriod = self.sceneModel.selectedPeriod {
                self.updateSelectedPeriod(selectedPeriod)
            }
        }
        
        private func onChartPriceDidChange(_ price: Decimal? = nil, timestamp: Date? = nil) {
            let selectedAssetPair = self.sceneModel.assetPair
            
            let response = Event.ChartPairPriceDidChange.Response(
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
            self.presenter.presentChartPairPriceDidChange(response: response)
        }
        
        private func onTradesDidUpdate() {
            let trades: [Model.Trade] = self.sceneModel.trades
            let hasMoreItems = self.tradesFetcher.getHasMoreItems()
            let response = Event.TradesDidUpdate.Response.trades(
                trades: trades,
                hasMoreItems: hasMoreItems
            )
            self.presenter.presentTradesDidUpdate(response: response)
        }
    }
}

extension TradeOffers.Interactor: TradeOffers.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        self.updateScreenTitle()
        
        self.sceneModel.selectedTab = .orderBook
        self.updatedSelectedContent(self.sceneModel.selectedTab)
        
        let selectedIndex = self.selectedTabIndex
        
        let response = Event.ViewDidLoad.Response(
            assetPair: self.sceneModel.assetPair,
            tabs: self.sceneModel.tabs,
            selectedIndex: selectedIndex,
            periods: self.sceneModel.periods,
            selectedPeriodIndex: self.selectedPeriodIndex
        )
        self.presenter.presentViewDidLoad(response: response)
        
        self.observeOffers(pageSize: request.offersPageSize)
        self.loadCharts()
        self.observeTrades(pageSize: request.tradesPageSize)
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
        
        if let index = request.index, index < charts.count {
            let chart = charts[index]
            self.onChartPriceDidChange(chart.value, timestamp: chart.date)
        } else {
            self.onChartPriceDidChange()
        }
    }
    
    public func onDidSelectPeriod(request: Event.DidSelectPeriod.Request) {
        self.updateSelectedPeriod(request.period)
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
    
    public func onPullToRefresh(request: Event.PullToRefresh.Request) {
        switch request {
            
        case .orderBook:
            self.offersFetcher.reloadOrderBook()
            
        case .chart:
            break
            
        case .trades:
            self.tradesFetcher.reloadItems()
        }
    }
    
    public func onLoadMore(request: Event.LoadMore.Request) {
        switch request {
            
        case .orderBook, .chart:
            break
            
        case .trades:
            self.tradesFetcher.loadMoreItems()
        }
    }
    
    public func onSwipeRecognized(request: Event.SwipeRecognized.Request) {
        guard let selectedTabIndex = self.sceneModel.tabs.indexOf(self.sceneModel.selectedTab) else {
            return
        }
        
        let indexToGo: Int
        switch request {
            
        case .left:
            indexToGo = selectedTabIndex + 1
        case .right:
            indexToGo = selectedTabIndex - 1
        }
        if self.sceneModel.tabs.indexInBounds(indexToGo) {
            let response = Event.SwipeRecognized.Response(index: indexToGo)
            self.presenter.presentSwipeRecognized(response: response)
        }
    }
}
