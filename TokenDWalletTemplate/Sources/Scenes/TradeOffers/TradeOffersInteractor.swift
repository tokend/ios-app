import Foundation

public protocol TradeOffersBusinessLogic {
    typealias Event = TradeOffers.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onContentTabSelected(request: Event.ContentTabSelected.Request)
    func onDidHighlightChart(request: Event.DidHighlightChart.Request)
    func onDidSelectPeriod(request: Event.DidSelectPeriod.Request)
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
            
            // TODO: Fix
            
            let response = Event.ContentTabSelected.Response(selectedTab: self.sceneModel.selectedTab)
            self.presenter.presentContentTabSelected(response: response)
        }
        
        private func updateCharts() {
            self.onLoading(showForChart: true, showForBuyTable: nil, showForSellTable: nil, showForAssets: nil)
            self.chartsFetcher.cancelRequests()
            let selectedPair = self.sceneModel.assetPair
            
            self.chartsFetcher.getChartsForBaseAsset(
                selectedPair.baseAsset,
                quoteAsset: selectedPair.quoteAsset
            ) { [weak self] (result) in
                
                switch result {
                    
                case .success(let charts):
                    self?.sceneModel.charts = charts
                    self?.onChartsDidChange()
                    self?.onLoading(
                        showForChart: false,
                        showForBuyTable: nil,
                        showForSellTable: nil,
                        showForAssets: nil
                    )
                    
                case .failure:
                    self?.onLoading(
                        showForChart: false,
                        showForBuyTable: nil,
                        showForSellTable: nil,
                        showForAssets: nil
                    )
                }
            }
        }
        
        private func onChartsDidChange() {
            self.sceneModel.periods = Array((self.sceneModel.charts ?? [:]).keys).sorted(by: { (left, right) -> Bool in
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
        
        private func updateTrades() {
            self.sceneModel.buyOffers = nil
            self.sceneModel.sellOffers = nil
            self.onLoading(showForChart: nil, showForBuyTable: true, showForSellTable: true, showForAssets: nil)
            self.onBuyOffersDidChange()
            self.onSellOffersDidChange()
            self.offersFetcher.cancelRequests()
            
            let selectedPair = self.sceneModel.assetPair
            
            self.onLoading(
                showForChart: nil,
                showForBuyTable: false,
                showForSellTable: false,
                showForAssets: nil
            )
            
            self.offersFetcher.getOffers(
                forBuy: true,
                base: selectedPair.baseAsset,
                quote: selectedPair.quoteAsset) { [weak self] (result) in
                    switch result {
                        
                    case .failed:
                        self?.onLoading(
                            showForChart: nil,
                            showForBuyTable: false,
                            showForSellTable: nil,
                            showForAssets: nil
                        )
                        
                    case .succeeded(let offers):
                        self?.sceneModel.buyOffers = offers
                        self?.onLoading(
                            showForChart: nil,
                            showForBuyTable: false,
                            showForSellTable: nil,
                            showForAssets: nil
                        )
                    }
                    
                    self?.onBuyOffersDidChange()
            }
            
            self.offersFetcher.getOffers(
                forBuy: false,
                base: selectedPair.baseAsset,
                quote: selectedPair.quoteAsset) { [weak self] (result) in
                    switch result {
                        
                    case .failed:
                        self?.onLoading(
                            showForChart: nil,
                            showForBuyTable: nil,
                            showForSellTable: false,
                            showForAssets: nil
                        )
                        
                    case .succeeded(let offers):
                        self?.sceneModel.sellOffers = offers
                        self?.onLoading(
                            showForChart: nil,
                            showForBuyTable: nil,
                            showForSellTable: false,
                            showForAssets: nil
                        )
                    }
                    
                    self?.onSellOffersDidChange()
            }
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
        
        private func onLoading(
            showForChart: Bool?,
            showForBuyTable: Bool?,
            showForSellTable: Bool?,
            showForAssets: Bool?
            ) {
            
            let response = Event.Loading.Response(
                showForChart: showForChart,
                showForBuyTable: showForBuyTable,
                showForSellTable: showForSellTable
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
            tabs: self.sceneModel.tabs,
            selectedIndex: selectedIndex
        )
        self.presenter.presentViewDidLoad(response: response)
        
        self.updatedSelectedContent(self.sceneModel.selectedTab)
    }
    
    public func onContentTabSelected(request: Event.ContentTabSelected.Request) {
        self.updatedSelectedContent(request.selectedTab)
    }
    
    public func onDidHighlightChart(request: Event.DidHighlightChart.Request) {
        
    }
    
    public func onDidSelectPeriod(request: Event.DidSelectPeriod.Request) {
        
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
