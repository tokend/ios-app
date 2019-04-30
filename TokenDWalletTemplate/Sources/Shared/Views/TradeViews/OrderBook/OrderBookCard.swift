import UIKit

class OrderBookCard: UIView {
    
    // MARK: - Public properties
    
    public var baseCurrency: String = "" {
        didSet {
            self.priceBidTitleLabel.text = Localized(
                .bid_base,
                replace: [
                    .bid_base_replace_base: self.baseCurrency
                ]
            )
            self.priceAskTitleLabel.text = Localized(
                .ask_base,
                replace: [
                    .ask_base_replace_base: self.baseCurrency
                ]
            )
        }
    }
    
    public var buyCells: [OrderBookTableViewCellModel<OrderBookTableViewBuyCell>] {
        get { return self.buyTable.cells }
        set { self.buyTable.cells = newValue }
    }
    
    public var sellCells: [OrderBookTableViewCellModel<OrderBookTableViewSellCell>] {
        get { return self.sellTable.cells }
        set { self.sellTable.cells = newValue }
    }
    
    // MARK: - Private properties
    
    private let priceBidTitleLabel: UILabel = UILabel()
    private let amountTitleLabel: UILabel = UILabel()
    private let priceAskTitleLabel: UILabel = UILabel()
    
    private let verticalSeparator: UIView = UIView()
    
    private let buyTable: OrderBookTableView = OrderBookTableView<OrderBookTableViewBuyCell>()
    private let horizontalSeparator: UIView = UIView()
    private let sellTable: OrderBookTableView = OrderBookTableView<OrderBookTableViewSellCell>()
    
    // MARK: - Overridden methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.commonInit()
    }
    
    // MARK: - Private
    
    private func commonInit() {
        self.setupCard()
        
        self.setupPriceBidTitleLabel()
        self.setupAmountTitleLabel()
        self.setupPriceAskTitleLabel()
        self.setupSeparators()
        self.setupTables()
        self.setupLayout()
    }
    
    private func setupCard() {
        self.backgroundColor = Theme.Colors.contentBackgroundColor
    }
    
    private func setupTables() {
        
    }
    
    private func setupSeparators() {
        self.verticalSeparator.backgroundColor = Theme.Colors.separatorOnMainColor
        self.horizontalSeparator.backgroundColor =  Theme.Colors.separatorOnMainColor
    }
    
    private func setupPriceBidTitleLabel() {
        self.priceBidTitleLabel.textAlignment = .left
        self.priceBidTitleLabel.textColor = Theme.Colors.sideTextOnContentBackgroundColor
        self.priceBidTitleLabel.font = Theme.Fonts.smallTextFont
        self.priceBidTitleLabel.numberOfLines = 1
        self.priceBidTitleLabel.text = Localized(.bid_base)
    }
    
    private func setupAmountTitleLabel() {
        self.amountTitleLabel.textAlignment = .center
        self.amountTitleLabel.textColor = Theme.Colors.sideTextOnContentBackgroundColor
        self.amountTitleLabel.font = Theme.Fonts.smallTextFont
        self.amountTitleLabel.numberOfLines = 1
        self.amountTitleLabel.text = Localized(.amount)
    }
    
    private func setupPriceAskTitleLabel() {
        self.priceAskTitleLabel.textAlignment = .right
        self.priceAskTitleLabel.textColor = Theme.Colors.sideTextOnContentBackgroundColor
        self.priceAskTitleLabel.font = Theme.Fonts.smallTextFont
        self.priceAskTitleLabel.numberOfLines = 1
        self.priceAskTitleLabel.text = Localized(.ask_base)
    }
    
    private func setupLayout() {
        self.addSubview(self.priceBidTitleLabel)
        self.addSubview(self.amountTitleLabel)
        self.addSubview(self.priceAskTitleLabel)
        self.addSubview(self.buyTable)
        self.addSubview(self.sellTable)
        self.addSubview(self.horizontalSeparator)
        self.addSubview(self.verticalSeparator)
        
        let sideInset: CGFloat = 14.0
        
        self.amountTitleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(sideInset)
        }
        
        self.priceBidTitleLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().inset(sideInset)
            make.centerY.equalTo(self.amountTitleLabel)
        }
        
        self.priceAskTitleLabel.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().inset(sideInset)
            make.centerY.equalTo(self.amountTitleLabel)
        }
        
        let separatorWidth: CGFloat = 1.0 / UIScreen.main.scale
        self.horizontalSeparator.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().inset(45.0)
            make.height.equalTo(separatorWidth)
        }
        
        self.verticalSeparator.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.horizontalSeparator.snp.bottom)
            make.bottom.equalToSuperview()
            make.width.equalTo(separatorWidth)
        }
        
        self.buyTable.snp.makeConstraints { (make) in
            make.leading.equalToSuperview()
            make.trailing.equalTo(self.verticalSeparator.snp.leading)
            make.top.equalTo(self.horizontalSeparator.snp.bottom)
            make.bottom.equalToSuperview()
        }
        
        self.sellTable.snp.makeConstraints { (make) in
            make.leading.equalTo(self.verticalSeparator.snp.trailing)
            make.trailing.equalToSuperview()
            make.top.equalTo(self.horizontalSeparator.snp.bottom)
            make.bottom.equalToSuperview()
        }
    }
    
    // MARK: - Public
    
    func showTableLoading(isBuy: Bool, show: Bool) {
        if isBuy {
            self.buyTable.showDataLoading(show)
        } else {
            self.sellTable.showDataLoading(show)
        }
    }
    
    func showEmptyTable(isBuy: Bool, text: String) {
        if isBuy {
            self.buyTable.showEmptyStateWithText(text)
            self.buyTable.cells = []
        } else {
            self.sellTable.showEmptyStateWithText(text)
            self.sellTable.cells = []
        }
    }
    
    func hideEmptyTable(isBuy: Bool) {
        if isBuy {
            self.buyTable.hideEmptyState()
        } else {
            self.sellTable.hideEmptyState()
        }
    }
    
    func setCallbacks(
        isBuy: Bool,
        onPullToRefresh: (() -> Void)?,
        onScrolledToBottom: (() -> Void)?
        ) {
        
        if isBuy {
            self.buyTable.onPullToRefresh = onPullToRefresh
            self.buyTable.onScrolledToBottom = onScrolledToBottom
        } else {
            self.sellTable.onPullToRefresh = onPullToRefresh
            self.sellTable.onScrolledToBottom = onScrolledToBottom
        }
    }
}
