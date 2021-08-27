import UIKit

extension BalanceDetailsScene {
    
    class BalanceView: UIView {
        
        // MARK: Private properties
        
        private let iconImageView: UIImageView = .init()
        private let abbreviationLabel: UILabel = .init()
        private let titleLabel: UILabel = .init()
        private let balanceLabel: UILabel = .init()
        
        private var iconSize: CGSize { .init(width: 80.0, height: 80.0) }
        
        // MARK: Public properties
        
        public var icon: TokenDUIImage? {
            didSet {
                iconImageView.setTokenDUIImage(icon)
            }
        }
        
        public var abbreviation: String? {
            get { abbreviationLabel.text }
            set { abbreviationLabel.text = newValue }
        }
        
        public var title: String? {
            get { titleLabel.text }
            set { titleLabel.text = newValue }
        }
        
        public var balance: String? {
            get { balanceLabel.text }
            set { balanceLabel.text = newValue }
        }
        
        // MARK:
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            commonInit()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            
            commonInit()
        }
    }
}

// MARK: Private methods

private extension BalanceDetailsScene.BalanceView {
    
    func commonInit() {
        setupView()
        setupIconImageView()
        setupAbbreviationLabel()
        setupTitleLabel()
        setupBalanceLabel()
        setupLayout()
    }
    
    func setupView() {
        backgroundColor = .clear
    }
    
    func setupIconImageView() {
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.layer.cornerRadius = iconSize.height / 2.0
        iconImageView.layer.masksToBounds = true
        iconImageView.backgroundColor = .clear
    }
    
    func setupAbbreviationLabel() {
        abbreviationLabel.font = Theme.Fonts.regularFont.withSize(24.0)
        abbreviationLabel.textColor = .white
        abbreviationLabel.numberOfLines = 1
        abbreviationLabel.textAlignment = .center
        abbreviationLabel.backgroundColor = .abbreviationColor()
        abbreviationLabel.lineBreakMode = .byWordWrapping
        abbreviationLabel.layer.cornerRadius = iconSize.height / 2.0
        abbreviationLabel.layer.masksToBounds = true
    }
    
    func setupTitleLabel() {
        titleLabel.font = Theme.Fonts.mediumFont.withSize(16.0)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .center
        titleLabel.backgroundColor = .white
        titleLabel.lineBreakMode = .byWordWrapping
    }
    
    func setupBalanceLabel() {
        balanceLabel.font = Theme.Fonts.mediumFont.withSize(32.0)
        balanceLabel.textColor = .black
        balanceLabel.numberOfLines = 1
        balanceLabel.textAlignment = .center
        balanceLabel.backgroundColor = .white
        balanceLabel.lineBreakMode = .byWordWrapping
    }
    
    func setupLayout() {
        addSubview(abbreviationLabel)
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(balanceLabel)
        
        abbreviationLabel.snp.makeConstraints { (make) in
            make.edges.equalTo(iconImageView)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(iconSize)
            make.top.equalToSuperview().inset(8.0)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().inset(8.0)
            make.trailing.lessThanOrEqualToSuperview().inset(8.0)
        }
        
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8.0)
            make.top.equalTo(iconImageView.snp.bottom).offset(8.0)
        }
        
        balanceLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        balanceLabel.setContentHuggingPriority(.required, for: .vertical)
        balanceLabel.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview().inset(8.0)
            make.top.equalTo(titleLabel.snp.bottom).offset(8.0)
        }
    }
}
