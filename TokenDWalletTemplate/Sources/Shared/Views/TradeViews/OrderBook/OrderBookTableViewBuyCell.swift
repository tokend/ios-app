import UIKit

public class OrderBookTableViewBuyCell: UITableViewCell {
    
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
    
    public var coefficient: Double? {
        didSet {
            self.updateProgress()
        }
    }
    
    // MARK: - Private properties
    
    private let priceLabel: UILabel = UILabel()
    private let amountLabel: UILabel = UILabel()
    private let gradientView: UIView = UIView()
    private let progressView: UIView = UIView()
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
        self.setupProgressView()
        self.setupLoadingIndicator()
        
        self.setupLayout()
    }
    
    private func setupPriceLabel() {
        self.priceLabel.numberOfLines = 1
        self.priceLabel.textColor = Theme.Colors.positiveAmountColor
        self.priceLabel.font = Theme.Fonts.smallTextFont
        self.priceLabel.textAlignment = .left
    }
    
    private func setupAmountLabel() {
        self.amountLabel.numberOfLines = 1
        self.amountLabel.textColor = Theme.Colors.textOnContentBackgroundColor
        self.amountLabel.font = Theme.Fonts.smallTextFont
        self.amountLabel.textAlignment = .right
    }
    
    private func setupProgressView() {
        self.progressView.backgroundColor = Theme.Colors.orderBookVolumeColor
    }
    
    private func setupLoadingIndicator() {
        self.loadingIndicator.hidesWhenStopped = true
    }
    
    private func setupLayout() {
        self.contentView.addSubview(self.gradientView)
        self.contentView.addSubview(self.amountLabel)
        self.contentView.addSubview(self.priceLabel)
        self.contentView.addSubview(self.loadingIndicator)
        
        self.gradientView.addSubview(self.progressView)
        
        let sideInset: CGFloat = 14
        
        self.priceLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().inset(sideInset)
            make.centerY.equalToSuperview()
        }
        
        self.gradientView.snp.makeConstraints { (make) in
            make.leading.equalTo(self.contentView.snp.centerX)
            make.trailing.equalToSuperview().inset(sideInset)
            make.centerY.equalToSuperview()
            make.height.equalTo(self.amountLabel.snp.height).offset(5.0)
        }
        
        self.amountLabel.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().inset(sideInset)
            make.centerY.equalToSuperview()
        }
        
        self.loadingIndicator.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
    
    private func updateProgress() {
        guard let coefficient = self.coefficient else {
            return
        }
        self.progressView.snp.remakeConstraints { (make) in
            make.trailing.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(coefficient)
        }
    }
}

extension OrderBookTableViewBuyCell: OrderBookTableViewCellProtocol {
    
    public func setPrice(_ price: String) {
        self.priceLabel.text = price
    }
    
    public func setAmount(_ amount: String) {
        self.amountLabel.text = amount
    }
    
    public func setVolumeCoefficient(_ coefficient: Double) {
        self.coefficient = coefficient
    }
    
    public func setLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }
}
