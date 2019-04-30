import UIKit

public class TradesTableViewCell: UITableViewCell {
    
    // MARK: - Public properties
    
    public static let identifier: String = "TradesTableViewCell"
    public static let horizontalInset: CGFloat = 14.0
    
    public var price: String? {
        get { return self.priceLabel.text }
        set { self.priceLabel.text = newValue }
    }
    
    public var amount: String? {
        get { return self.amountLabel.text }
        set { self.amountLabel.text = newValue }
    }
    
    public var time: String? {
        get { return self.timeLabel.text }
        set { self.timeLabel.text = newValue }
    }
    
    public var priceGrowth: Bool = false {
        didSet {
            self.priceLabel.textColor = self.priceGrowth
                ? Theme.Colors.positiveAmountColor
                : Theme.Colors.negativeAmountColor
        }
    }
    
    public var isLoading: Bool = false {
        didSet {
            self.priceLabel.isHidden = self.isLoading
            self.amountLabel.isHidden = self.isLoading
            self.timeLabel.isHidden = self.isLoading
            
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
    private let timeLabel: UILabel = UILabel()
    private let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .gray)
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.customInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.customInit()
    }
    
    private func customInit() {
        self.setupView()
        self.setupPriceLabel()
        self.setupAmountLabel()
        self.setupTimeLabel()
        self.setupLoadingIndicator()
        
        self.setupLayout()
    }
    
    // MARK: - Private
    
    private func setupView() {
        self.selectionStyle = .none
    }
    
    private func setupPriceLabel() {
        self.priceLabel.font = Theme.Fonts.smallTextFont
        self.priceLabel.textColor = Theme.Colors.textOnContentBackgroundColor
    }
    
    private func setupAmountLabel() {
        self.amountLabel.font = Theme.Fonts.smallTextFont
        self.amountLabel.textColor = Theme.Colors.textOnContentBackgroundColor
    }
    
    private func setupTimeLabel() {
        self.timeLabel.font = Theme.Fonts.smallTextFont
        self.amountLabel.textColor = Theme.Colors.textOnContentBackgroundColor
    }
    
    private func setupLoadingIndicator() {
        self.loadingIndicator.hidesWhenStopped = true
    }
    
    private func setupLayout() {
        self.contentView.addSubview(self.priceLabel)
        self.contentView.addSubview(self.amountLabel)
        self.contentView.addSubview(self.timeLabel)
        self.contentView.addSubview(self.loadingIndicator)
        
        self.priceLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().inset(TradesTableViewCell.horizontalInset)
            make.centerY.equalToSuperview()
        }
        
        self.amountLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        
        self.timeLabel.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().inset(TradesTableViewCell.horizontalInset)
            make.centerY.equalToSuperview()
        }
        
        self.loadingIndicator.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
}
