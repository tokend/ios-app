import UIKit

public class OrderBookTableViewSellCell: UITableViewCell {
    
    // MARK: - Public properties
    
    public var isLoading: Bool = false {
        didSet {
            self.priceLabel.isHidden = self.isLoading
            self.amountLabel.isHidden = self.isLoading
            
            if self.isLoading {
                self.loadingIndicator.startAnimating()
            } else {
                self.loadingIndicator.stopAnimating()
            }
        }
    }
    
    // MARK: - Private properties
    
    private let priceLabel: UILabel = UILabel()
    private let amountLabel: UILabel = UILabel()
    private let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .gray)
    
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
        self.setupLoadingIndicator()
        
        self.setupLayout()
    }
    
    private func setupPriceLabel() {
        self.priceLabel.numberOfLines = 1
        self.priceLabel.textColor = Theme.Colors.negativeAmountColor
        self.priceLabel.font = Theme.Fonts.smallTextFont
        self.priceLabel.textAlignment = .right
    }
    
    private func setupLoadingIndicator() {
        self.loadingIndicator.hidesWhenStopped = true
    }
    
    private func setupAmountLabel() {
        self.amountLabel.numberOfLines = 1
        self.amountLabel.textColor = Theme.Colors.textOnContentBackgroundColor
        self.amountLabel.font = Theme.Fonts.smallTextFont
        self.amountLabel.textAlignment = .left
    }
    
    private func setupLayout() {
        self.contentView.addSubview(self.amountLabel)
        self.contentView.addSubview(self.priceLabel)
        self.contentView.addSubview(self.loadingIndicator)
        
        let sideInset: CGFloat = 14
        
        self.amountLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().inset(sideInset)
            make.centerY.equalToSuperview()
        }
        
        self.priceLabel.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().inset(sideInset)
            make.centerY.equalToSuperview()
        }
        
        self.loadingIndicator.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
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
    
    public func setLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }
}
