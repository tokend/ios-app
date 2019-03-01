import Foundation
import RxSwift
import RxCocoa

protocol TradeBusinessLogic {
    func onViewDidLoadSync(request: Trade.Event.ViewDidLoadSync.Request)
    func onViewWillAppear(request: Trade.Event.ViewWillAppear.Request)
    func onDidSelectPair(request: Trade.Event.DidSelectPair.Request)
    func onDidSelectPeriod(request: Trade.Event.DidSelectPeriod.Request)
    func onDidHighlightChart(request: Trade.Event.DidHighlightChart.Request)
    func onCreateOffer(request: Trade.Event.CreateOffer.Request)
}

extension Trade {
    typealias BusinessLogic = TradeBusinessLogic
    
    class Interactor {
        
        private var sceneModel: Model.SceneModel = Model.SceneModel(
            pairs: [],
            selectedPair: nil,
            selectedPeriod: nil,
            charts: nil,
            buyOffers: [],
            sellOffers: [],
            periods: []
        )
        
        private var selectedPairIndex: Int? {
            return self.sceneModel.pairs.index(where: { (pair) -> Bool in
                return pair.id == self.sceneModel.selectedPair?.id
            })
        }
        
        private var selectedPeriodIndex: Int? {
            guard let selectedPeriod = self.sceneModel.selectedPeriod else { return nil }
            return self.sceneModel.periods.index(of: selectedPeriod)
        }
        
        private let presenter: PresentationLogic
        private let assetsFetcher: AssetsFetcherProtocol
        private let chartsFetcher: ChartsFetcherProtocol
        private let tradeOffersFetcher: TradeOffersFetcherProtocol
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        init(
            presenter: PresentationLogic,
            assetsFetcher: AssetsFetcherProtocol,
            chartsFetcher: ChartsFetcherProtocol,
            tradeOffersFetcher: TradeOffersFetcherProtocol
            ) {
            
            self.presenter = presenter
            self.assetsFetcher = assetsFetcher
            self.chartsFetcher = chartsFetcher
            self.tradeOffersFetcher = tradeOffersFetcher
        }
        
        private func updateAssets() {
            self.assetsFetcher.updateAssets()
        }
        
        private func observeAssets() {
            self.assetsFetcher
                .observeAssets()
                .subscribe(onNext: { [weak self] (pairs) in
                    guard let strongSelf = self else { return }
                    
                    let oldSelectedID = strongSelf.sceneModel.selectedPair?.id
                    strongSelf.sceneModel.pairs = pairs
                    strongSelf.selectPair(oldSelectedID)
                    let pairs = strongSelf.sceneModel.pairs.map({ (pair) -> Trade.Model.Pair in
                        return Trade.Model.Pair(base: pair.baseAsset, quote: pair.quoteAsset, id: pair.id)
                    })
                    let response = Trade.Event.PairsDidChange.Response(
                        pairs: pairs,
                        selectedPairIndex: strongSelf.selectedPairIndex
                    )
                    strongSelf.presenter.presentPairsDidChange(response: response)
                    strongSelf.onPriceDidChange()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeAssetsLoadingStatus() {
            self.assetsFetcher
                .observeAssetsLoadingStatus()
                .subscribe(onNext: { [weak self] (status) in
                    switch status {
                        
                    case .loading:
                        self?.onLoading(
                            showForChart: nil,
                            showForBuyTable: nil,
                            showForSellTable: nil,
                            showForAssets: true
                        )
                        
                    case .loaded:
                        self?.onLoading(
                            showForChart: nil,
                            showForBuyTable: nil,
                            showForSellTable: nil,
                            showForAssets: false
                        )
                    }
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeAssetsErrorStatus() {
            self.assetsFetcher
                .observeAssetsError()
                .subscribe(onNext: { [weak self] (error) in
                    let response = Trade.Event.Error.Response(error: error)
                    self?.presenter.presentError(response: response)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func updateSelectedPair(_ id: PairID?) {
            let optionalPair = self.sceneModel.pairs.first(where: { (pair) -> Bool in
                return pair.id == id
            })
            self.sceneModel.selectedPair = optionalPair ?? self.sceneModel.pairs.first
        }
        
        private func onPriceDidChange(_ price: Decimal? = nil, forTimestamp timestamp: Date? = nil) {
            let response: Event.PairPriceDidChange.Response
            
            if let selected = self.sceneModel.selectedPair {
                response = Event.PairPriceDidChange.Response(
                    price: Trade.Model.Amount(value: price ?? selected.currentPrice, currency: selected.quoteAsset),
                    per: Trade.Model.Amount(value: 1, currency: selected.baseAsset),
                    timestamp: timestamp
                )
            } else {
                response = Event.PairPriceDidChange.Response(price: nil, per: nil, timestamp: nil)
            }
            self.presenter.presentPairPriceDidChange(response: response)
        }
        
        private func updateCharts() {
            self.onLoading(showForChart: true, showForBuyTable: nil, showForSellTable: nil, showForAssets: nil)
            self.chartsFetcher.cancelRequests()
            guard let selectedPair = self.sceneModel.selectedPair else {
                self.onLoading(showForChart: false, showForBuyTable: nil, showForSellTable: nil, showForAssets: nil)
                return
                
            }
            
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
        
        private func chartsDidChange(_ charts: [Trade.Model.Chart]?) {
            let response = Trade.Event.ChartDidUpdate.Response(charts: charts)
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
            self.tradeOffersFetcher.cancelRequests()
            guard let selectedPair = self.sceneModel.selectedPair else {
                self.onLoading(showForChart: nil, showForBuyTable: false, showForSellTable: false, showForAssets: nil)
                return
            }
            
            self.tradeOffersFetcher.getOffers(
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
            
            self.tradeOffersFetcher.getOffers(
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
            let response = Trade.Event.BuyOffersDidUpdate.Response(offers: offers)
            self.presenter.presentBuyOffersDidUpdate(response: response)
            return offers != nil
        }
        
        @discardableResult
        private func onSellOffersDidChange() -> Bool {
            let offers = self.sceneModel.sellOffers
            let response = Trade.Event.SellOffersDidUpdate.Response(offers: offers)
            self.presenter.presentSellOffersDidUpdate(response: response)
            return offers != nil
        }
        
        private func onLoading(
            showForChart: Bool?,
            showForBuyTable: Bool?,
            showForSellTable: Bool?,
            showForAssets: Bool?
            ) {
            
            let response = Trade.Event.Loading.Response(
                showForChart: showForChart,
                showForBuyTable: showForBuyTable,
                showForSellTable: showForSellTable,
                showForAssets: showForAssets
            )
            self.presenter.presentLoading(response: response)
        }
        
        private func selectPeriod(_ period: Trade.Model.Period) {
            self.sceneModel.selectedPeriod = period
            self.onChartsDidChange()
            
            let response = Trade.Event.ChartFormatterDidChange.Response(period: period)
            self.presenter.presentChartFormatterDidChange(response: response)
        }
        
        private func selectPair(_ id: Trade.PairID?) {
            self.updateSelectedPair(id)
            self.onPriceDidChange()
            self.updateCharts()
            self.updateTrades()
            
            let selectedPair = self.sceneModel.selectedPair
            let response = Trade.Event.DidSelectPair.Response(
                base: selectedPair?.baseAsset,
                quote: selectedPair?.quoteAsset
            )
            self.presenter.presentDidSelectPair(response: response)
        }
    }
}

extension Trade.Interactor: Trade.BusinessLogic {
    func onViewDidLoadSync(request: Trade.Event.ViewDidLoadSync.Request) {
        self.observeAssets()
        self.observeAssetsErrorStatus()
        self.observeAssetsLoadingStatus()
        self.updateAssets()
        
        let pairs = self.sceneModel.pairs.map({ (pair) -> Trade.Model.Pair in
            return Trade.Model.Pair(base: pair.baseAsset, quote: pair.quoteAsset, id: pair.id)
        })
        
        let response = Trade.Event.ViewDidLoadSync.Response(
            pairs: pairs,
            selectedPairIndex: self.selectedPairIndex,
            selectedPeriodIndex: self.selectedPeriodIndex,
            base: self.sceneModel.selectedPair?.baseAsset,
            quote: self.sceneModel.selectedPair?.quoteAsset,
            periods: self.sceneModel.periods
        )
        self.presenter.presentViewDidLoadSync(response: response)
        self.selectPair(self.sceneModel.selectedPair?.id)
        if let period = self.sceneModel.selectedPeriod {
            self.selectPeriod(period)
        }
    }
    
    func onViewWillAppear(request: Trade.Event.ViewWillAppear.Request) {
        self.updateAssets()
        self.updateCharts()
        self.updateTrades()
    }
    
    func onDidSelectPair(request: Trade.Event.DidSelectPair.Request) {
        self.selectPair(request.pairID)
    }
    
    func onDidSelectPeriod(request: Trade.Event.DidSelectPeriod.Request) {
        self.selectPeriod(request.period)
    }
    
    func onDidHighlightChart(request: Trade.Event.DidHighlightChart.Request) {
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
    
    func onCreateOffer(request: Trade.Event.CreateOffer.Request) {
        guard let selectedPair = self.sceneModel.selectedPair else { return }
        
        let response = Trade.Event.CreateOffer.Response(
            amount: request.amount,
            price: request.price,
            baseAsset: selectedPair.baseAsset,
            quoteAsset: selectedPair.quoteAsset
        )
        self.presenter.presentCreateOffer(response: response)
    }
}

private extension Trade.Model.Asset {
    var id: Trade.PairID {
        let baseAsset = self.baseAsset
        let quoteAsset = self.quoteAsset
        return "\(baseAsset)/\(quoteAsset)"
    }
}

private extension Trade.Model.Period {
    var weight: Int {
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
