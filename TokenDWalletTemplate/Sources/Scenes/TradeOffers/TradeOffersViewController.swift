import UIKit
import Charts
import RxCocoa
import RxSwift

public protocol TradeOffersDisplayLogic: class {
    typealias Event = TradeOffers.Event
    
    func displayViewDidLoad(viewModel: Event.ViewDidLoad.ViewModel)
    func displayScreenTitleUpdated(viewModel: Event.ScreenTitleUpdated.ViewModel)
    func displayContentTabSelected(viewModel: Event.ContentTabSelected.ViewModel)
    func displayChartPeriodsDidChange(viewModel: Event.ChartPeriodsDidChange.ViewModel)
    func displayChartPairPriceDidChange(viewModel: Event.ChartPairPriceDidChange.ViewModel)
    func displayChartDidUpdate(viewModel: Event.ChartDidUpdate.ViewModel)
    func displayOffersDidUpdate(viewModel: Event.OffersDidUpdate.ViewModel)
    func displayTradesDidUpdate(viewModel: Event.TradesDidUpdate.ViewModel)
    func displayLoading(viewModel: Event.Loading.ViewModel)
    func displayChartFormatterDidChange(viewModel: Event.ChartFormatterDidChange.ViewModel)
    func displayCreateOffer(viewModel: Event.CreateOffer.ViewModel)
    func displaySwipeRecognized(viewModel: Event.SwipeRecognized.ViewModel)
}

extension TradeOffers {
    public typealias DisplayLogic = TradeOffersDisplayLogic
    
    @objc(TradeOffersViewController)
    public class ViewController: UIViewController {
        
        public typealias Event = TradeOffers.Event
        public typealias Model = TradeOffers.Model
        
        // MARK: - Private
        
        private let picker: HorizontalPicker = HorizontalPicker(frame: CGRect.zero)
        private let containerView: UIView = UIView()
        private let leftSwipeRecognizer: UISwipeGestureRecognizer = UISwipeGestureRecognizer()
        private let rightSwipeRecognizer: UISwipeGestureRecognizer = UISwipeGestureRecognizer()
        
        private let chartCardValueFormatter: ChartCardValueFormatter = ChartCardValueFormatter()
        
        private lazy var orderBookView: OrderBookCard = {
            let view = OrderBookCard()
            self.layoutContentView(view)
            return view
        }()
        
        private lazy var chartView: TradeChartCard = {
            let view = TradeChartCard(frame: CGRect.zero)
            self.layoutContentView(view)
            return view
        }()
        
        private lazy var tradesView: TradesView = {
            let view = TradesView()
            view.backgroundColor = Theme.Colors.contentBackgroundColor
            self.layoutContentView(view)
            return view
        }()
        
        private let disposeBag = DisposeBag()
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        private var onDeinit: DeinitCompletion = nil
        
        public func inject(
            interactorDispatch: InteractorDispatch?,
            routing: Routing?,
            onDeinit: DeinitCompletion = nil
            ) {
            
            self.interactorDispatch = interactorDispatch
            self.routing = routing
            self.onDeinit = onDeinit
        }
        
        // MARK: - Overridden
        
        public override func viewDidLoad() {
            super.viewDidLoad()
            
            self.setupPicker()
            self.setupContainerView()
            self.setupOrderBookView()
            self.setupChartView()
            self.setupTradesView()
            self.setupNavigationBar()
            self.setupSwipeRecognizer(direction: .left)
            self.setupSwipeRecognizer(direction: .right)
            self.setupLayout()
            
            let request = Event.ViewDidLoad.Request(
                offersPageSize: 20,
                tradesPageSize: 20
            )
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        public override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            let request = Event.ViewWillAppear.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewWillAppear(request: request)
            }
        }
        
        // MARK: - Private
        
        private func setupSwipeRecognizer(direction: UISwipeGestureRecognizer.Direction) {
            switch direction {
                
            case .left:
                self.leftSwipeRecognizer.direction = .left
                self.leftSwipeRecognizer
                    .rx
                    .event
                    .asDriver()
                    .drive(onNext: { [weak self] (_) in
                        self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                            businessLogic.onSwipeRecognized(request: .left)
                        })
                    })
                    .disposed(by: self.disposeBag)
                
            case .right:
                self.rightSwipeRecognizer.direction = .right
                self.rightSwipeRecognizer
                    .rx
                    .event
                    .asDriver()
                    .drive(onNext: { [weak self] (_) in
                        self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                            businessLogic.onSwipeRecognized(request: .right)
                        })
                    })
                    .disposed(by: self.disposeBag)
                
            default:
                break
            }
        }
        
        private func setupPicker() {
            self.picker.backgroundColor = Theme.Colors.mainColor
            self.picker.tintColor = Theme.Colors.darkAccentColor
        }
        
        private func setupContainerView() {
            self.containerView.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupOrderBookView() {
            self.orderBookView.setCallbacks(
                onPullToRefresh: { [weak self] in
                    let request = Event.PullToRefresh.Request.orderBook
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onPullToRefresh(request: request)
                    })
                }
            )
        }
        
        private func setupChartView() {
            self.chartView.yAxisValueFormatter = self.chartCardValueFormatter
            self.chartView.xAxisValueFormatter = self.chartCardValueFormatter
            self.chartView.didSelectItemAtIndex = { [weak self] (index, card) in
                let request = Event.DidHighlightChart.Request(index: index)
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onDidHighlightChart(request: request)
                })
            }
        }
        
        private func setupTradesView() {
            self.tradesView.onPullToRefresh = { [weak self] in
                let request = Event.PullToRefresh.Request.trades
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onPullToRefresh(request: request)
                })
            }
            self.tradesView.onScrolledToBottom = { [weak self] in
                let request = Event.LoadMore.Request.trades
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onLoadMore(request: request)
                })
            }
        }
        
        private func layoutContentView(_ contentView: UIView) {
            contentView.isHidden = true
            self.containerView.addSubview(contentView)
            self.containerView.sendSubviewToBack(contentView)
            contentView.snp.makeConstraints({ (make) in
                make.edges.equalToSuperview()
            })
        }
        
        private func setupNavigationBar() {
            var items: [UIBarButtonItem] = []
            
            let createOfferButton = UIBarButtonItem(
                image: Assets.addIcon.image,
                style: .plain,
                target: nil,
                action: nil
            )
            createOfferButton.rx
                .tap
                .asDriver()
                .drive(onNext: { [weak self] in
                    self?.onCreateOffer()
                })
                .disposed(by: self.disposeBag)
            items.append(createOfferButton)
            
            let showPendingButton = UIBarButtonItem(
                image: Assets.pendingIcon.image,
                style: .plain,
                target: nil,
                action: nil
            )
            showPendingButton.rx
                .tap
                .asDriver()
                .drive(onNext: { [weak self] in
                    self?.showPendingTransactions()
                })
                .disposed(by: self.disposeBag)
            items.append(showPendingButton)
            
            self.navigationItem.rightBarButtonItems = items
        }
        
        private func setupLayout() {
            self.view.addSubview(self.picker)
            self.view.addSubview(self.containerView)
            self.view.addGestureRecognizer(self.leftSwipeRecognizer)
            self.view.addGestureRecognizer(self.rightSwipeRecognizer)
            
            self.picker.snp.makeConstraints { (make) in
                make.leading.trailing.top.equalToSuperview()
            }
            
            self.containerView.snp.makeConstraints { (make) in
                make.top.equalTo(self.picker.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
        }
        
        private func setContentTab(_ tab: Model.ContentTab) {
            var hideOrderBookView = true
            var hideChartView = true
            var hideTradesView = true
            
            switch tab {
            case .orderBook:
                hideOrderBookView = false
            case .chart:
                hideChartView = false
            case .trades:
                hideTradesView = false
            }
            
            self.orderBookView.isHidden = hideOrderBookView
            self.chartView.isHidden = hideChartView
            self.tradesView.isHidden = hideTradesView
        }
        
        private func onCreateOffer() {
            let request = Event.CreateOffer.Request(amount: nil, price: nil)
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                businessLogic.onCreateOffer(request: request)
            })
        }
        
        private func showPendingTransactions() {
            self.routing?.onSelectPendingOffers()
        }
        
        private func setPeriods(_ periods: [Model.PeriodViewModel]) {
            self.chartView.periods = periods.map({ [weak self] (period) -> HorizontalPicker.Item in
                return HorizontalPicker.Item(
                    title: period.title,
                    enabled: period.isEnabled,
                    onSelect: { [weak self] in
                        guard let period = period.period else { return }
                        let request = Event.DidSelectPeriod.Request(
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
                self.chartView.selectPeriodAtIndex(index)
            }
        }
        
        private func setupCells<CellType: OrderBookTableViewCell>(
            _ cells: [OrderBookTableViewCellModel<CellType>]
            ) -> [OrderBookTableViewCellModel<CellType>] {
            
            var cells = cells
            for cellIndex in 0..<cells.count {
                let offer = cells[cellIndex].offer
                cells[cellIndex].onClick = { [weak self] (_) in
                    let request = Event.CreateOffer.Request(
                        amount: offer.amount.amount,
                        price: offer.price.amount
                    )
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onCreateOffer(request: request)
                    })
                }
            }
            return cells
        }
        
        private func setAxisFormatters(axisFormatters: Model.AxisFormatters) {
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

extension TradeOffers.ViewController: TradeOffers.DisplayLogic {
    
    public func displayViewDidLoad(viewModel: Event.ViewDidLoad.ViewModel) {
        self.picker.items = viewModel.tabs.map({ (title, tab) -> HorizontalPicker.Item in
            return HorizontalPicker.Item(
                title: title,
                enabled: true,
                onSelect: { [weak self] in
                    let request = Event.ContentTabSelected.Request(selectedTab: tab)
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onContentTabSelected(request: request)
                    })
            })
        })
        self.picker.setSelectedItemAtIndex(viewModel.selectedIndex ?? 0, animated: false)
        
        self.orderBookView.quoteCurrency = viewModel.assetPair.quoteAsset
        
        self.setPeriods(viewModel.periods)
        self.setSelectedPeriodIndex(viewModel.selectedPeriodIndex)
        
        self.setAxisFormatters(axisFormatters: viewModel.axisFomatters)
        
        self.tradesView.baseAsset = viewModel.assetPair.baseAsset
        self.tradesView.quoteAsset = viewModel.assetPair.quoteAsset
    }
    
    public func displayScreenTitleUpdated(viewModel: Event.ScreenTitleUpdated.ViewModel) {
        let titleView = TradeOffers.TitleView()
        titleView.title = viewModel.screenTitle
        titleView.subTitle = viewModel.screenSubTitle
        self.navigationItem.titleView = titleView
    }
    
    public func displayContentTabSelected(viewModel: Event.ContentTabSelected.ViewModel) {
        self.setContentTab(viewModel.selectedTab)
    }
    
    public func displayChartPeriodsDidChange(viewModel: Event.ChartPeriodsDidChange.ViewModel) {
        self.setPeriods(viewModel.periods)
        self.setSelectedPeriodIndex(viewModel.selectedPeriodIndex)
    }
    
    public func displayChartPairPriceDidChange(viewModel: Event.ChartPairPriceDidChange.ViewModel) {
        self.chartView.title = viewModel.price
        self.chartView.subtitle = viewModel.per
    }
    
    public func displayChartDidUpdate(viewModel: Event.ChartDidUpdate.ViewModel) {
        switch viewModel {
            
        case .charts(let chartEntries):
            if chartEntries.isEmpty {
                self.chartView.emptyMessage = Localized(.no_chart_entries)
            } else {
                self.chartView.emptyMessage = ""
            }
            self.chartView.chartEntries = chartEntries
            
        case .error(let error):
            self.chartView.chartEntries = []
            self.chartView.emptyMessage = error
        }
    }
    
    public func displayOffersDidUpdate(viewModel: Event.OffersDidUpdate.ViewModel) {
        switch viewModel {
            
        case .error(let error):
            self.orderBookView.showEmptyTable(isBuy: true, text: error)
            self.orderBookView.showEmptyTable(isBuy: false, text: error)
            
        case .cells(let buy, let sell):
            let buy = self.setupCells(buy)
            let sell = self.setupCells(sell)
            
            if buy.isEmpty {
                self.orderBookView.showEmptyTable(isBuy: true, text: Localized(.no_bids))
                self.orderBookView.buyCells = []
            } else {
                self.orderBookView.hideEmptyTable(isBuy: true)
                self.orderBookView.buyCells = buy
            }
            
            if sell.isEmpty {
                self.orderBookView.showEmptyTable(isBuy: false, text: Localized(.no_asks))
                self.orderBookView.sellCells = []
            } else {
                self.orderBookView.hideEmptyTable(isBuy: false)
                self.orderBookView.sellCells = sell
            }
        }
    }
    
    public func displayTradesDidUpdate(viewModel: Event.TradesDidUpdate.ViewModel) {
        switch viewModel {
            
        case .error(let error):
            self.tradesView.emptyMessage = error
            self.tradesView.trades = []
            
        case .trades(let trades):
            let emptyMessage: String?
            let tradesModels: [TradesView.Trade]
            
            if trades.count > 0 {
                emptyMessage = nil
                tradesModels = trades.map { (tradeViewModel) -> TradesView.Trade in
                    return TradesView.Trade(
                        amount: tradeViewModel.amount,
                        price: tradeViewModel.price,
                        time: tradeViewModel.time,
                        priceGrowth: tradeViewModel.priceGrowth,
                        isLoading: tradeViewModel.isLoading
                    )
                }
            } else {
                emptyMessage = Localized(.no_trade_entries)
                tradesModels = []
            }
            
            self.tradesView.emptyMessage = emptyMessage
            self.tradesView.trades = tradesModels
        }
    }
    
    public func displayLoading(viewModel: Event.Loading.ViewModel) {
        let show = viewModel.isLoading
        switch viewModel.content {
            
        case .orderBook:
            self.orderBookView.showTableLoading(show: show)
            
        case .chart:
            self.chartView.showChartLoading(show)
            
        case .trades:
            self.tradesView.showTradesLoading(show)
        }
    }
    
    public func displayChartFormatterDidChange(viewModel: Event.ChartFormatterDidChange.ViewModel) {
        self.setAxisFormatters(axisFormatters: viewModel.axisFormatters)
    }
    
    public func displayCreateOffer(viewModel: Event.CreateOffer.ViewModel) {
        if let amount = viewModel.amount,
            let price = viewModel.price {
            self.routing?.onDidSelectOffer(amount, price)
        } else {
            self.routing?.onDidSelectNewOffer(viewModel.baseAsset, viewModel.quoteAsset)
        }
    }
    
    public func displaySwipeRecognized(viewModel: Event.SwipeRecognized.ViewModel) {
        self.picker.setSelectedItemAtIndex(viewModel.index, animated: true)
        self.picker.items[viewModel.index].onSelect()
    }
}

extension OrderBookTableViewCellModel.Amount {
    
    fileprivate var amount: TradeOffers.Model.Amount {
        return TradeOffers.Model.Amount(
            value: self.value,
            currency: self.currency
        )
    }
}
