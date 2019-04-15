import UIKit

public class OrderBookTableViewSellCell: UITableViewCell {
    
    // MARK: - Private properties
    
    private let priceLabel: UILabel = UILabel()
    private let amountLabel: UILabel = UILabel()
    
    // MARK: - Overridden methods
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private
    
    private func commonInit() {
        self.selectionStyle = .none
        self.setupPriceLabel()
        self.setupAmountLabel()
        
        self.setupLayout()
    }
    
    private func setupPriceLabel() {
        self.priceLabel.numberOfLines = 1
        self.priceLabel.setContentHuggingPriority(.required, for: .horizontal)
        self.priceLabel.setContentHuggingPriority(.required, for: .vertical)
        self.priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.priceLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        self.priceLabel.textColor = Theme.Colors.negativeAmountColor
        self.priceLabel.font = Theme.Fonts.smallTextFont
        self.priceLabel.textAlignment = .left
        self.priceLabel.backgroundColor = Theme.Colors.contentBackgroundColor
        self.priceLabel.layer.shadowColor = Theme.Colors.contentBackgroundColor.cgColor
        self.priceLabel.layer.shadowRadius = 2
        self.priceLabel.layer.shadowOpacity = 1
        self.priceLabel.layer.shadowOffset = CGSize(width: 6, height: 0)
    }
    
    private func setupAmountLabel() {
        self.amountLabel.numberOfLines = 1
        self.amountLabel.setContentHuggingPriority(.required, for: .horizontal)
        self.amountLabel.setContentHuggingPriority(.required, for: .vertical)
        self.amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.amountLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        self.amountLabel.textColor = Theme.Colors.textOnContentBackgroundColor
        self.amountLabel.font = Theme.Fonts.smallTextFont
        self.amountLabel.textAlignment = .right
        self.amountLabel.backgroundColor = Theme.Colors.contentBackgroundColor
    }
    
    private func setupLayout() {
        self.addSubview(self.amountLabel)
        self.addSubview(self.priceLabel)
        
        let sideInset: CGFloat = 16
        let betweenDistance: CGFloat = 12
        let topBottomInset: CGFloat = 8
        
        self.priceLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(topBottomInset)
            make.bottom.equalToSuperview().inset(topBottomInset + 1)
            make.leading.equalToSuperview().inset(betweenDistance)
            make.trailing.greaterThanOrEqualTo(self.amountLabel.snp.leading)
        }
        
        self.amountLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(topBottomInset)
            make.bottom.equalToSuperview().inset(topBottomInset + 1)
            make.trailing.equalToSuperview().inset(sideInset)
        }
    }
}

extension OrderBookTableViewSellCell: OrderBookTableViewCellProtocol {
    
    public func setPrice(_ price: String) {
        self.priceLabel.text = price
    }
    
    public func setAmount(_ amount: String) {
        self.amountLabel.text = amount
    }
}
