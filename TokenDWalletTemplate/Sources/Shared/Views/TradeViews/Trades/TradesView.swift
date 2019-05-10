import UIKit
import RxCocoa
import RxSwift

public class TradesView: UIView {
    
    public struct Trade {
        
        public let amount: String
        public let price: String
        public let time: String
        public let priceGrowth: Bool
        public let isLoading: Bool
        
        public init(
            amount: String,
            price: String,
            time: String,
            priceGrowth: Bool,
            isLoading: Bool
            ) {
            
            self.amount = amount
            self.price = price
            self.time = time
            self.priceGrowth = priceGrowth
            self.isLoading = isLoading
        }
    }
    
    // MARK: - Public properties
    
    public static let cellHeight: CGFloat = 35.0
    
    public var quoteAsset: String = "" {
        didSet {
            let title = Localized(.trades_header_price_quote, replace: [
                .trades_header_price_quote_replace_asset: self.quoteAsset
                ]
            )
            self.headerQuotePriceLabel.text = title
        }
    }
    
    public var baseAsset: String = "" {
        didSet {
            let title = Localized(.trades_header_amount_base, replace: [
                .trades_header_amount_base_replace_asset: self.baseAsset
                ]
            )
            self.headerBaseAmountLabel.text = title
        }
    }
    
    public var trades: [Trade] = [] {
        didSet {
            self.everScrolled = false
            self.lastIndexPath = IndexPath(row: self.trades.count - 1, section: 0)
            self.reloadData()
            self.updateEmptyState()
        }
    }
    
    public var emptyMessage: String? {
        get { return self.emptyViewLabel.text }
        set {
            self.emptyViewLabel.text = newValue
            self.updateEmptyState()
        }
    }
    
    public var onPullToRefresh: (() -> Void)?
    public var onScrolledToBottom: (() -> Void)?
    
    // MARK: - Private properties
    
    private let headerView: UIView = UIView()
    private let headerQuotePriceLabel: UILabel = UILabel()
    private let headerBaseAmountLabel: UILabel = UILabel()
    private let headerTimeLabel: UILabel = UILabel()
    private let separatorView: UIView = UIView()
    private let tableView: UITableView = UITableView()
    private let refreshControl: UIRefreshControl = UIRefreshControl()
    private let emptyViewLabel: UILabel = UILabel()
    
    private var everScrolled: Bool = false
    private var lastIndexPath: IndexPath?
    
    private let disposeBag = DisposeBag()
    
    // MARK: -
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.customInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.customInit()
    }
    
    private func customInit() {
        self.setupView()
        self.setupHeaderView()
        self.setupHeaderQuotePriceLabel()
        self.setupHeaderBaseAmountLabel()
        self.setupHeaderTimeLabel()
        self.setupSeparatorView()
        self.setupTableView()
        self.setupRefreshControl()
        self.setupEmptyViewLabel()
        self.setupLayout()
    }
    
    // MARK: - Public
    
    public func showTradesLoading(_ show: Bool) {
        if show {
            self.refreshControl.beginRefreshing()
        } else {
            self.refreshControl.endRefreshing()
        }
    }
    
    // MARK: - Private
    
    private func setupView() {
        self.backgroundColor = Theme.Colors.contentBackgroundColor
    }
    
    private func setupHeaderView() {
        self.headerView.backgroundColor = Theme.Colors.contentBackgroundColor
    }
    
    private func setupHeaderQuotePriceLabel() {
        self.headerQuotePriceLabel.font = Theme.Fonts.smallTextFont
        self.headerQuotePriceLabel.textColor = Theme.Colors.sideTextOnContentBackgroundColor
    }
    
    private func setupHeaderBaseAmountLabel() {
        self.headerBaseAmountLabel.font = Theme.Fonts.smallTextFont
        self.headerBaseAmountLabel.textColor = Theme.Colors.sideTextOnContentBackgroundColor
    }
    
    private func setupHeaderTimeLabel() {
        self.headerTimeLabel.font = Theme.Fonts.smallTextFont
        self.headerTimeLabel.textColor = Theme.Colors.sideTextOnContentBackgroundColor
        self.headerTimeLabel.text = Localized(.trades_header_time)
    }
    
    private func setupSeparatorView() {
        self.separatorView.backgroundColor = Theme.Colors.separatorOnContentBackgroundColor
    }
    
    private func setupTableView() {
        self.tableView.rowHeight = TradesView.cellHeight
        self.tableView.separatorStyle = .none
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(
            TradesTableViewCell.self,
            forCellReuseIdentifier: TradesTableViewCell.identifier
        )
    }
    
    private func setupRefreshControl() {
        self.refreshControl.rx
            .controlEvent(.valueChanged)
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.onPullToRefresh?()
            }).disposed(by: self.disposeBag)
    }
    
    private func setupEmptyViewLabel() {
        self.emptyViewLabel.textColor = Theme.Colors.sideTextOnContainerBackgroundColor
        self.emptyViewLabel.font = Theme.Fonts.smallTextFont
        self.emptyViewLabel.textAlignment = .center
        self.emptyViewLabel.numberOfLines = 0
    }
    
    private func setupLayout() {
        self.addSubview(self.tableView)
        self.tableView.addSubview(self.refreshControl)
        self.addSubview(self.headerView)
        self.addSubview(self.separatorView)
        self.addSubview(self.emptyViewLabel)
        self.headerView.addSubview(self.headerQuotePriceLabel)
        self.headerView.addSubview(self.headerBaseAmountLabel)
        self.headerView.addSubview(self.headerTimeLabel)
        
        self.headerView.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(TradesView.cellHeight)
        }
        
        self.headerQuotePriceLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().inset(TradesTableViewCell.horizontalInset)
            make.centerY.equalToSuperview()
        }
        
        self.headerBaseAmountLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        
        self.headerTimeLabel.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().inset(TradesTableViewCell.horizontalInset)
            make.centerY.equalToSuperview()
        }
        
        self.separatorView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.headerView.snp.bottom)
            make.height.equalTo(1.0)
        }
        
        self.tableView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.separatorView.snp.bottom)
            make.bottom.equalTo(self.safeArea.bottom)
        }
        
        self.emptyViewLabel.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(TradesTableViewCell.horizontalInset)
            make.centerY.equalToSuperview()
        }
    }
    
    // MARK: -
    
    private func reloadData() {
        self.tableView.reloadData()
    }
    
    private func updateEmptyState() {
        let hasTradesEntries = self.trades.count > 0
        
        self.emptyViewLabel.isHidden = hasTradesEntries
    }
}

// MARK: - UITableViewDataSource

extension TradesView: UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.trades.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = TradesTableViewCell.identifier
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: identifier,
            for: indexPath) as? TradesTableViewCell else {
                return UITableViewCell()
        }
        
        let trade = self.trades[indexPath.row]
        
        cell.price = trade.price
        cell.amount = trade.amount
        cell.time = trade.time
        cell.priceGrowth = trade.priceGrowth
        cell.isLoading = trade.isLoading
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension TradesView: UITableViewDelegate {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.everScrolled, self.tableView.isLastCellVisible(lastCellIndexPath: self.lastIndexPath) {
            self.onScrolledToBottom?()
        }
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.everScrolled = true
    }
    
    public func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
        ) {
        
        if self.everScrolled, indexPath.row == self.trades.count - 1 {
            self.onScrolledToBottom?()
        }
    }
}
