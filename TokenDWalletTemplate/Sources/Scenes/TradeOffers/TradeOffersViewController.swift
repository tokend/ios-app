import UIKit
import Charts
import RxCocoa
import RxSwift

public protocol TradeOffersDisplayLogic: class {
    typealias Event = TradeOffers.Event
    
    func displayViewDidLoad(viewModel: Event.ViewDidLoad.ViewModel)
    func displayScreenTitleUpdated(viewModel: Event.ScreenTitleUpdated.ViewModel)
    func displayContentTabSelected(viewModel: Event.ContentTabSelected.ViewModel)
    func displayPeriodsDidChange(viewModel: Event.PeriodsDidChange.ViewModel)
    func displayPairPriceDidChange(viewModel: Event.PairPriceDidChange.ViewModel)
    func displayChartDidUpdate(viewModel: Event.ChartDidUpdate.ViewModel)
    func displaySellOffersDidUpdate(viewModel: Event.SellOffersDidUpdate.ViewModel)
    func displayBuyOffersDidUpdate(viewModel: Event.BuyOffersDidUpdate.ViewModel)
    func displayTradesDidUpdate(viewModel: Event.TradesDidUpdate.ViewModel)
    func displayLoading(viewModel: Event.Loading.ViewModel)
    func displayChartFormatterDidChange(viewModel: Event.ChartFormatterDidChange.ViewModel)
    func displayError(viewModel: Event.Error.ViewModel)
    func displayCreateOffer(viewModel: Event.CreateOffer.ViewModel)
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
        
        private let chartCardValueFormatter: ChartCardValueFormatter = ChartCardValueFormatter()
        
        private lazy var orderBookView: OrderBookCard = {
            let view = OrderBookCard()
            self.layoutContentView(view)
            return view
        }()
        
        private lazy var chartView: TradeChartCard = {
            let view = TradeChartCard(frame: CGRect.zero)
            self.layoutContentView(view, maxHeight: 450.0)
            return view
        }()
        
        private lazy var tradesView: UIView = {
            let view = UIView()
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
            self.setupNavigationBar()
            self.setupLayout()
            
            let request = Event.ViewDidLoad.Request()
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
        
        private func setupPicker() {
            self.picker.backgroundColor = Theme.Colors.mainColor
            self.picker.tintColor = Theme.Colors.textOnMainColor
        }
        
        private func setupContainerView() {
            self.containerView.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupOrderBookView() {
            
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
        
        private func layoutContentView(_ contentView: UIView, maxHeight: CGFloat? = nil) {
            contentView.isHidden = true
            self.containerView.addSubview(contentView)
            self.containerView.sendSubviewToBack(contentView)
            contentView.snp.makeConstraints({ (make) in
                make.leading.trailing.top.equalToSuperview()
                if let maxHeight = maxHeight {
                    make.height.lessThanOrEqualTo(maxHeight)
                    make.bottom.lessThanOrEqualToSuperview()
                } else {
                    make.bottom.equalToSuperview()
                }
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
        self.picker.setSelectedItemAtIndex(viewModel.selectedIndex, animated: false)
        
        self.orderBookView.baseCurrency = viewModel.assetPair.baseAsset
        self.orderBookView.quoteCurrency = viewModel.assetPair.quoteAsset
        
        self.setPeriods(viewModel.periods)
        self.setSelectedPeriodIndex(viewModel.selectedPeriodIndex)
        
        self.setAxisFormatters(axisFormatters: viewModel.axisFomatters)
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
    
    public func displayPeriodsDidChange(viewModel: Event.PeriodsDidChange.ViewModel) {
        self.setPeriods(viewModel.periods)
        self.setSelectedPeriodIndex(viewModel.selectedPeriodIndex)
    }
    
    public func displayPairPriceDidChange(viewModel: Event.PairPriceDidChange.ViewModel) {
        self.chartView.title = viewModel.price
        self.chartView.subtitle = viewModel.per
    }
    
    public func displayChartDidUpdate(viewModel: Event.ChartDidUpdate.ViewModel) {
        self.chartView.chartEntries = viewModel.chartEntries
    }
    
    public func displaySellOffersDidUpdate(viewModel: Event.SellOffersDidUpdate.ViewModel) {
        switch viewModel {
        case .empty:
            self.orderBookView.showEmptySellTable(Localized(.no_asks))
            self.orderBookView.sellCells = []
        case .cells(let cells):
            self.orderBookView.hideEmptySellTable()
            self.orderBookView.sellCells = self.setupCells(cells)
        }
    }
    
    public func displayBuyOffersDidUpdate(viewModel: Event.BuyOffersDidUpdate.ViewModel) {
        switch viewModel {
        case .empty:
            self.orderBookView.showEmptyBuyTable(Localized(.no_bids))
            self.orderBookView.buyCells = []
        case .cells(let cells):
            self.orderBookView.hideEmptyBuyTable()
            self.orderBookView.buyCells = self.setupCells(cells)
        }
    }
    
    public func displayTradesDidUpdate(viewModel: Event.TradesDidUpdate.ViewModel) {
        
    }
    
    public func displayLoading(viewModel: Event.Loading.ViewModel) {
        if let show = viewModel.showForChart { self.chartView.showChartLoading(show) }
        if let show = viewModel.showForBuyTable { self.orderBookView.showBuyTableLoading(show) }
        if let show = viewModel.showForSellTable { self.orderBookView.showSellTableLoading(show) }
    }
    
    public func displayChartFormatterDidChange(viewModel: Event.ChartFormatterDidChange.ViewModel) {
        self.setAxisFormatters(axisFormatters: viewModel.axisFormatters)
    }
    
    public func displayError(viewModel: Event.Error.ViewModel) {
        self.routing?.onShowError(viewModel.message)
    }
    
    public func displayCreateOffer(viewModel: Event.CreateOffer.ViewModel) {
        if let amount = viewModel.amount,
            let price = viewModel.price {
            self.routing?.onDidSelectOffer(amount, price)
        } else {
            self.routing?.onDidSelectNewOffer(viewModel.baseAsset, viewModel.quoteAsset)
        }
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
