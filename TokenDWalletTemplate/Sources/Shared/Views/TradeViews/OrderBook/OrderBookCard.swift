import UIKit

class OrderBookCard: UIView {
    
    // MARK: - Public properties
    
    public var baseCurrency: String? = nil {
        didSet {
            if let base = self.baseCurrency {
                self.buyTitleLabel.text = Localized(
                    .buy_base,
                    replace: [
                        .buy_base_replace_base: base
                    ]
                )
                self.sellTitleLabel.text = Localized(
                    .sell_base,
                    replace: [
                        .sell_base_replace_base: base
                    ]
                )
                self.amountBuyTitleLabel.text = Localized(
                    .amount_newline,
                    replace: [
                        .amount_newline_replace_base: base
                    ]
                )
                self.amountSellTitleLabel.text = Localized(
                    .amount_newline,
                    replace: [
                        .amount_newline_replace_base: base
                    ]
                )
            } else {
                self.buyTitleLabel.text = Localized(.buy)
                self.sellTitleLabel.text = Localized(.sell)
                self.amountBuyTitleLabel.text = Localized(.amount)
                self.amountSellTitleLabel.text = Localized(.amount)
            }
        }
    }
    public var quoteCurrency: String? = nil {
        didSet {
            if let quote = self.quoteCurrency {
                self.priceBuyTitleLabel.text = Localized(
                    .price_newline,
                    replace: [
                        .price_newline_replace_quote: quote
                    ]
                )
                self.priceSellTitleLabel.text = Localized(
                    .price_newline,
                    replace: [
                        .price_newline_replace_quote: quote
                    ]
                )
            } else {
                self.priceBuyTitleLabel.text = Localized(.price)
                self.priceSellTitleLabel.text = Localized(.price)
            }
        }
    }
    public var sellCells: [CellViewAnyModel] {
        get { return self.sellTable.cells }
        set { self.sellTable.cells = (newValue as? [OrderBookTableViewCellModel<OrderBookTableViewSellCell>]) ?? [] }
    }
    public var buyCells: [CellViewAnyModel] {
        get { return self.buyTable.cells }
        set { self.buyTable.cells = (newValue as? [OrderBookTableViewCellModel<OrderBookTableViewBuyCell>]) ?? [] }
    }
    
    // MARK: - Private properties
    
    private let buyTitleLabel: UILabel = UILabel()
    private let amountBuyTitleLabel: UILabel = UILabel()
    private let priceBuyTitleLabel: UILabel = UILabel()
    private let buyTable: OrderBookTableView = OrderBookTableView<OrderBookTableViewBuyCell>()
    
    private let minimumTableHeight: CGFloat = 44
    
    private let sellTitleLabel: UILabel = UILabel()
    private let amountSellTitleLabel: UILabel = UILabel()
    private let priceSellTitleLabel: UILabel = UILabel()
    private let sellTable: OrderBookTableView = OrderBookTableView<OrderBookTableViewSellCell>()
    
    private let orderBookTitleStackView: UIStackView = UIStackView()
    
    private let verticalSeparator: UIView = UIView()
    private let horizontalSeparator: UIView = UIView()
    
    // MARK: - Overridden methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private
    
    private func commonInit() {
        self.setupCard()
        self.setupTables()
        self.setupSeparators()
        self.setupBuyTitleLabel()
        self.setupSellTitleLabel()
        self.setupOrderBookTitleStackView()
        self.setupAmountBuyTitleLabel()
        self.setupPriceBuyTitleLabel()
        self.setupAmountSellTitleLabel()
        self.setupPriceSellTitleLabel()
        self.setupLayout()
    }
    
    private func setupCard() {
        self.backgroundColor = Theme.Colors.contentBackgroundColor
    }
    
    private func setupTables() {
        self.buyTable.onContentSizeChanged = { [weak self] (newSize) in
            self?.buyTable.snp.updateConstraints({ (make) in
                make.height.equalTo(max(newSize.height, self?.minimumTableHeight ?? 0))
            })
        }
        self.sellTable.onContentSizeChanged = { [weak self] (newSize) in
            self?.sellTable.snp.updateConstraints({ (make) in
                make.height.equalTo(max(newSize.height, self?.minimumTableHeight ?? 0))
            })
        }
    }
    
    private func setupSeparators() {
        self.verticalSeparator.backgroundColor = Theme.Colors.separatorOnMainColor
        self.horizontalSeparator.backgroundColor =  Theme.Colors.separatorOnMainColor
    }
    
    private func setupOrderBookTitleStackView() {
        self.orderBookTitleStackView.alignment = .fill
        self.orderBookTitleStackView.axis = .horizontal
        self.orderBookTitleStackView.distribution = .fillEqually
        self.orderBookTitleStackView.spacing = 24
    }
    
    private func setupBuyTitleLabel() {
        self.buyTitleLabel.textAlignment = .center
        self.buyTitleLabel.textColor = Theme.Colors.textOnContentBackgroundColor
        self.buyTitleLabel.font = Theme.Fonts.largeTitleFont
        self.buyTitleLabel.numberOfLines = 0
        self.buyTitleLabel.text = Localized(.buy)
    }
    
    private func setupAmountBuyTitleLabel() {
        self.amountBuyTitleLabel.textAlignment = .left
        self.amountBuyTitleLabel.textColor = Theme.Colors.sideTextOnContentBackgroundColor
        self.amountBuyTitleLabel.font = Theme.Fonts.smallTextFont
        self.amountBuyTitleLabel.numberOfLines = 0
        self.amountBuyTitleLabel.text = Localized(.amount)
    }
    
    private func setupPriceBuyTitleLabel() {
        self.priceBuyTitleLabel.textAlignment = .right
        self.priceBuyTitleLabel.textColor = Theme.Colors.sideTextOnContentBackgroundColor
        self.priceBuyTitleLabel.font = Theme.Fonts.smallTextFont
        self.priceBuyTitleLabel.numberOfLines = 0
        self.priceBuyTitleLabel.text = Localized(.price)
    }
    
    private func setupSellTitleLabel() {
        self.sellTitleLabel.textAlignment = .center
        self.sellTitleLabel.textColor = Theme.Colors.textOnContentBackgroundColor
        self.sellTitleLabel.font = Theme.Fonts.largeTitleFont
        self.sellTitleLabel.numberOfLines = 0
        self.sellTitleLabel.text = Localized(.sell)
    }
    
    private func setupAmountSellTitleLabel() {
        self.amountSellTitleLabel.textAlignment = .right
        self.amountSellTitleLabel.textColor = Theme.Colors.sideTextOnContentBackgroundColor
        self.amountSellTitleLabel.font = Theme.Fonts.smallTextFont
        self.amountSellTitleLabel.numberOfLines = 0
        self.amountSellTitleLabel.text = Localized(.amount)
    }
    
    private func setupPriceSellTitleLabel() {
        self.priceSellTitleLabel.textAlignment = .left
        self.priceSellTitleLabel.textColor = Theme.Colors.sideTextOnContentBackgroundColor
        self.priceSellTitleLabel.font = Theme.Fonts.smallTextFont
        self.priceSellTitleLabel.numberOfLines = 0
        self.priceSellTitleLabel.text = Localized(.price)
    }
    
    private func setupLayout() {
        self.addSubview(self.buyTitleLabel)
        self.addSubview(self.sellTitleLabel)
        self.addSubview(self.orderBookTitleStackView)
        self.orderBookTitleStackView.addArrangedSubview(self.amountBuyTitleLabel)
        self.orderBookTitleStackView.addArrangedSubview(self.priceBuyTitleLabel)
        self.orderBookTitleStackView.addArrangedSubview(self.priceSellTitleLabel)
        self.orderBookTitleStackView.addArrangedSubview(self.amountSellTitleLabel)
        self.addSubview(self.buyTable)
        self.addSubview(self.sellTable)
        self.addSubview(self.horizontalSeparator)
        self.addSubview(self.verticalSeparator)
        
        let sideInset: CGFloat = 16
        let betweenDistance: CGFloat = 24
        
        self.buyTitleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(16)
            make.leading.equalToSuperview().inset(sideInset)
            make.trailing.lessThanOrEqualTo(self.sellTitleLabel.snp.leading).offset(betweenDistance)
        }
        
        self.sellTitleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(16)
            make.leading.equalTo(self.snp.centerX).inset(12)
            make.trailing.lessThanOrEqualToSuperview().inset(sideInset)
        }
        
        self.orderBookTitleStackView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(sideInset)
            make.top.equalTo(self.buyTitleLabel.snp.bottom).offset(24)
        }
        
        self.horizontalSeparator.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.orderBookTitleStackView.snp.bottom).offset(8)
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }
        
        let verticalSeparatorWidth: CGFloat = 1.0 / UIScreen.main.scale
        self.verticalSeparator.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.horizontalSeparator.snp.bottom)
            make.bottom.equalToSuperview()
            make.width.equalTo(verticalSeparatorWidth)
        }
        
        let topBottomInset: CGFloat = 0
        
        self.buyTable.snp.makeConstraints { (make) in
            make.leading.equalToSuperview()
            make.top.equalTo(self.horizontalSeparator.snp.bottom).offset(topBottomInset)
            make.bottom.lessThanOrEqualToSuperview().inset(topBottomInset)
            make.trailing.equalTo(self.snp.centerX)
            make.height.equalTo(minimumTableHeight)
        }
        
        self.sellTable.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview()
            make.top.equalTo(self.horizontalSeparator.snp.bottom).offset(topBottomInset)
            make.bottom.lessThanOrEqualToSuperview().inset(topBottomInset)
            make.leading.equalTo(self.snp.centerX)
            make.height.equalTo(minimumTableHeight)
        }
    }
    
    // MARK: - Public
    
    func showBuyTableLoading(_ show: Bool) {
        if show {
            self.buyTable.showLoading()
        } else {
            self.buyTable.hideLoading()
        }
    }
    
    func showSellTableLoading(_ show: Bool) {
        if show {
            self.sellTable.showLoading()
        } else {
            self.sellTable.hideLoading()
        }
    }
    
    func showEmptyBuyTable(_ text: String) {
        self.buyTable.showEmptyStateWithText(text)
    }
    
    func hideEmptyBuyTable() {
        self.buyTable.hideEmptyState()
    }
    
    func showEmptySellTable(_ text: String) {
        self.sellTable.showEmptyStateWithText(text)
    }
    
    func hideEmptySellTable() {
        self.sellTable.hideEmptyState()
    }
}
