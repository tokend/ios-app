import UIKit
import Charts

protocol TradeDisplayLogic: class {
    func displayViewDidLoadSync(viewModel: Trade.Event.ViewDidLoadSync.ViewModel)
    func displayPairsDidChange(viewModel: Trade.Event.PairsDidChange.ViewModel)
    func displayPairPriceDidChange(viewModel: Trade.Event.PairPriceDidChange.ViewModel)
    func displayLoading(viewModel: Trade.Event.Loading.ViewModel)
    func displayChartDidUpdate(viewModel: Trade.Event.ChartDidUpdate.ViewModel)
    func displayDidSelectPair(viewModel: Trade.Event.DidSelectPair.ViewModel)
    func displaySellOffersDidUpdate(viewModel: Trade.Event.SellOffersDidUpdate.ViewModel)
    func displayBuyOffersDidUpdate(viewModel: Trade.Event.BuyOffersDidUpdate.ViewModel)
    func displayCreateOffer(viewModel: Trade.Event.CreateOffer.ViewModel)
    func displayChartFormatterDidChange(viewModel: Trade.Event.ChartFormatterDidChange.ViewModel)
    func displayPeriodsDidChange(viewModel: Trade.Event.PeriodsDidChange.ViewModel)
    func displayError(viewModel: Trade.Event.Error.ViewModel)
}

extension Trade {
    typealias DisplayLogic = TradeDisplayLogic
    
    class ViewController: UIViewController {
        
        private let pairPicker: HorizontalPicker = HorizontalPicker()
        private let scrollView = UIScrollView()
        
        private let chartCard: TradeChartCard = TradeChartCard()
        private let chartCardValueFormatter: ChartCardValueFormatter = ChartCardValueFormatter()
        private let orderBookCard: OrderBookCard = OrderBookCard()
        
        private let sideMargin: CGFloat = 0
        private let topBottomMargin: CGFloat = 32
        private let betweenMargin: CGFloat = 32
        
        private var pairs: [Model.PairViewModel] = []
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        
        func inject(interactorDispatch: InteractorDispatch?, routing: Routing?) {
            self.interactorDispatch = interactorDispatch
            self.routing = routing
        }
        
        // MARK: - Overridden
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.setupView()
            self.setupPairPicker()
            self.setupScrollView()
            self.setupTradeChartCard()
            self.setupOrderBookCard()
            self.setupLayout()
            
            let request = Trade.Event.ViewDidLoadSync.Request()
            self.interactorDispatch?.sendSyncRequest(requestBlock: { (businessLogic) in
                businessLogic.onViewDidLoadSync(request: request)
            })
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                let request = Event.ViewWillAppear.Request()
                businessLogic.onViewWillAppear(request: request)
            })
        }
        
        private func setupPairPicker() {
            self.pairPicker.backgroundColor = Theme.Colors.mainColor
            self.pairPicker.tintColor = Theme.Colors.textOnMainColor
        }
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.containerBackgroundColor
        }
        
        private func setupScrollView() {
            self.scrollView.isDirectionalLockEnabled = true
            self.scrollView.delaysContentTouches = true
            self.scrollView.canCancelContentTouches = false
            self.scrollView.showsVerticalScrollIndicator = false
            self.scrollView.showsHorizontalScrollIndicator = false
        }
        
        private func setupTradeChartCard() {
            self.chartCard.yAxisValueFormatter = self.chartCardValueFormatter
            self.chartCard.xAxisValueFormatter = self.chartCardValueFormatter
            self.chartCard.didSelectItemAtIndex = { [weak self] (index, card) in
                let request = Trade.Event.DidHighlightChart.Request(
                    index: index
                )
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onDidHighlightChart(request: request)
                })
            }
        }
        
        private func setPeriods(_ periods: [Trade.Model.PeriodViewModel]) {
            self.chartCard.periods = periods.map({ [weak self] (period) -> HorizontalPicker.Item in
                return HorizontalPicker.Item(
                    title: period.title,
                    enabled: period.isEnabled,
                    onSelect: { [weak self] in
                        guard let period = period.period else { return }
                        let request = Trade.Event.DidSelectPeriod.Request(
                            period: period
                        )
                        self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                            businessLogic.onDidSelectPeriod(request: request)
                        })
                })
            })
        }
        
        private func setSelectedPeriodIndex(_ index: Int?) {
            if let index = index {
                self.chartCard.selectPeriodAtIndex(index)
            }
        }
        
        private func setupOrderBookCard() { }
        
        private func setupLayout() {
            self.view.addSubview(self.scrollView)
            self.view.addSubview(self.pairPicker)
            
            self.pairPicker.snp.makeConstraints { (make) in
                make.top.equalToSuperview()
                make.leading.trailing.equalToSuperview()
            }
            
            self.scrollView.snp.makeConstraints { (make) in
                make.top.equalTo(self.pairPicker.snp.bottom)
                make.leading.bottom.trailing.equalToSuperview()
            }
            
            self.fillScrollView(withCards: [self.orderBookCard, self.chartCard])
        }
        
        private func fillScrollView(withCards cards: [UIView]) {
            var previousCard: UIView?
            
            for card in cards {
                self.scrollView.addSubview(card)
                
                card.snp.makeConstraints { (make) in
                    make.leading.equalToSuperview().inset(self.sideMargin)
                    make.trailing.equalToSuperview().inset(self.sideMargin)
                    make.width.equalTo(self.scrollView.snp.width).inset(self.sideMargin)
                    
                    if let previous = previousCard {
                        make.top.equalTo(previous.snp.bottom).offset(self.betweenMargin)
                    } else {
                        make.top.equalToSuperview().inset(self.topBottomMargin)
                    }
                }
                
                previousCard = card
            }
            
            previousCard?.snp.makeConstraints({ (make) in
                make.bottom.equalToSuperview().inset(self.topBottomMargin)
            })
        }
        
        private func updateHorizontalPickerWithViewModel(_ models: [Model.PairViewModel]) {
            self.pairs = models
            self.pairPicker.items = self.pairs.map({ (pair) -> HorizontalPicker.Item in
                return HorizontalPicker.Item(
                    title: pair.title,
                    enabled: true,
                    onSelect: {
                        let request = Event.DidSelectPair.Request(pairID: pair.id)
                        self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                            businessLogic.onDidSelectPair(request: request)
                        })
                })
            })
        }
        
        private func updateSelectedHorizontalPickerIndex(_ index: Int?) {
            if let selectedIndex = index {
                self.pairPicker.setSelectedItemAtIndex(selectedIndex, animated: false)
            }
        }
        
        private func updateOrderBookCardBaseCurrency(_ base: String?) {
            self.orderBookCard.baseCurrency = base
        }
        
        private func updateOrderBookCardQuoteCurrency(_ quote: String?) {
            self.orderBookCard.quoteCurrency = quote
        }
        
        private func setupNavigationBar() {
            var items: [UIBarButtonItem] = []
            
            let createBarButtonItem = UIBarButtonItem(
                image: Assets.addIcon.image,
                style: .plain,
                target: self,
                action: #selector(self.onCreateOffer)
            )
            items.append(createBarButtonItem)
            let pendingBarButtonItem = UIBarButtonItem(
                image: Assets.pendingIcon.image,
                style: .plain,
                target: self,
                action: #selector(self.showPendingTransactions)
            )
            items.append(pendingBarButtonItem)
            
            self.navigationItem.rightBarButtonItems = items
        }
        
        @objc private func onCreateOffer() {
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                let request = Event.CreateOffer.Request(amount: nil, price: nil)
                businessLogic.onCreateOffer(request: request)
            })
        }
        
        @objc private func showPendingTransactions() {
            self.routing?.onSelectPendingOffers()
        }
        
        private func showAssetsLoading(show: Bool) {
            if show {
                self.routing?.onShowProgress()
            } else {
                self.routing?.onHideProgress()
            }
        }
        
        private func setAxisFormatters(axisFormatters: Trade.Model.AxisFormatters) {
            self.chartCardValueFormatter.string = { (value, axis) in
                if axis is XAxis {
                    return axisFormatters.xAxisFormatter(value)
                } else if axis is YAxis {
                    return axisFormatters.yAxisFormatter(value)
                }
                return ""
            }
        }
    }
}

extension Trade.ViewController: Trade.DisplayLogic {
    func displayViewDidLoadSync(viewModel: Trade.Event.ViewDidLoadSync.ViewModel) {
        self.updateHorizontalPickerWithViewModel(viewModel.pairs)
        self.updateSelectedHorizontalPickerIndex(viewModel.selectedPairIndex)
        self.updateOrderBookCardBaseCurrency(viewModel.base)
        self.updateOrderBookCardQuoteCurrency(viewModel.quote)
        self.setPeriods(viewModel.periods)
        self.setupNavigationBar()
        self.setSelectedPeriodIndex(viewModel.selectedPeriodIndex)
        self.setAxisFormatters(axisFormatters: viewModel.axisFomatters)
    }
    
    func displayPairsDidChange(viewModel: Trade.Event.PairsDidChange.ViewModel) {
        self.updateHorizontalPickerWithViewModel(viewModel.pairs)
        self.updateSelectedHorizontalPickerIndex(viewModel.selectedPairIndex)
    }
    
    func displayPairPriceDidChange(viewModel: Trade.Event.PairPriceDidChange.ViewModel) {
        self.chartCard.title = viewModel.price
        self.chartCard.subtitle = viewModel.per
    }
    
    func displayLoading(viewModel: Trade.Event.Loading.ViewModel) {
        if let show = viewModel.showForChart { self.chartCard.showChartLoading(show) }
        if let show = viewModel.showForBuyTable { self.orderBookCard.showBuyTableLoading(show) }
        if let show = viewModel.showForSellTable { self.orderBookCard.showSellTableLoading(show) }
        if let show = viewModel.showForAssets { self.showAssetsLoading(show: show) }
    }
    
    func displayChartDidUpdate(viewModel: Trade.Event.ChartDidUpdate.ViewModel) {
        self.chartCard.chartEntries = viewModel.chartEntries
    }
    
    func displayDidSelectPair(viewModel: Trade.Event.DidSelectPair.ViewModel) {
        self.updateOrderBookCardBaseCurrency(viewModel.base)
        self.updateOrderBookCardQuoteCurrency(viewModel.quote)
    }
    
    func displayBuyOffersDidUpdate(viewModel: Trade.Event.BuyOffersDidUpdate.ViewModel) {
        switch viewModel {
        case .empty:
            self.orderBookCard.showEmptyBuyTable(Localized(.no_bids))
            self.orderBookCard.buyCells = []
        case .cells(let cells):
            self.orderBookCard.hideEmptyBuyTable()
            self.orderBookCard.buyCells = self.setupCells(cells)
        }
    }
    
    func displaySellOffersDidUpdate(viewModel: Trade.Event.SellOffersDidUpdate.ViewModel) {
        switch viewModel {
        case .empty:
            self.orderBookCard.showEmptySellTable(Localized(.no_asks))
            self.orderBookCard.sellCells = []
        case .cells(let cells):
            self.orderBookCard.hideEmptySellTable()
            self.orderBookCard.sellCells = self.setupCells(cells)
        }
    }
    
    private func setupCells<CellType: OrderBookTableViewCell>(
        _ cells: [OrderBookTableViewCellModel<CellType>]
        ) -> [OrderBookTableViewCellModel<CellType>] {
        
        var cells = cells
        for cellIndex in 0..<cells.count {
            let offer = cells[cellIndex].offer
            cells[cellIndex].onClick = { [weak self] (_) in
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    let request = Trade.Event.CreateOffer.Request(
                        amount: offer.amount.amount,
                        price: offer.price.amount
                    )
                    businessLogic.onCreateOffer(request: request)
                })
            }
        }
        return cells
    }
    
    func displayCreateOffer(viewModel: Trade.Event.CreateOffer.ViewModel) {
        if let amount = viewModel.amount,
            let price = viewModel.price {
            self.routing?.onDidSelectOffer(amount, price)
        } else {
            self.routing?.onDidSelectNewOffer(viewModel.baseAsset, viewModel.quoteAsset)
        }
    }
    
    func displayChartFormatterDidChange(viewModel: Trade.Event.ChartFormatterDidChange.ViewModel) {
        self.setAxisFormatters(axisFormatters: viewModel.axisFormatters)
    }
    
    func displayPeriodsDidChange(viewModel: Trade.Event.PeriodsDidChange.ViewModel) {
        self.setPeriods(viewModel.periods)
        self.setSelectedPeriodIndex(viewModel.selectedPeriodIndex)
    }
    
    func displayError(viewModel: Trade.Event.Error.ViewModel) {
        self.routing?.onShowError(viewModel.message)
    }
}

extension OrderBookTableViewCellModel.Amount {
    
    fileprivate var amount: Trade.Model.Amount {
        return Trade.Model.Amount(
            value: self.value,
            currency: self.currency
        )
    }
}
