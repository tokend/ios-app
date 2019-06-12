import UIKit

extension SendPaymentAmount {
    class BalanceView: UIView {
        
        // MARK: - Public properties
        
        public var title: String? {
            get { return self.titleLabel.text }
            set { self.titleLabel.text = newValue }
        }
        
        // MARK: - Private properties
        
        private let containerView: UIView = UIView()
        private let titleLabel: UILabel = UILabel()
        private let amountLabel: UILabel = UILabel()
        
        // MARK: -
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.customInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            
            self.customInit()
        }
        
        private func customInit() {
            self.setupView()
            self.setupContainerView()
            self.setupTitleLabel()
            self.setupAmountLabel()
            self.setupLayout()
        }
        
        // MARK: - Public
        
        func set(amount: String?, asset: String?) {
            guard let amount = amount, let asset = asset else {
                self.amountLabel.text = nil
                return
            }
            self.amountLabel.text = "\(amount) \(asset)"
            
            if let title = title {
                self.titleLabel.text = title
            }
        }
        
        func set(balanceHighlighted: Bool) {
            self.amountLabel.textColor = balanceHighlighted
                ? Theme.Colors.negativeColor
                : Theme.Colors.separatorOnContentBackgroundColor
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupContainerView() {
            self.containerView.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupTitleLabel() {
            self.titleLabel.backgroundColor = Theme.Colors.contentBackgroundColor
            self.titleLabel.font = Theme.Fonts.smallTextFont
            self.titleLabel.text = Localized(.balance_colon)
            self.titleLabel.textColor = Theme.Colors.separatorOnContentBackgroundColor
        }
        
        private func setupAmountLabel() {
            self.amountLabel.backgroundColor = Theme.Colors.contentBackgroundColor
            self.amountLabel.font = Theme.Fonts.smallTextFont
            self.amountLabel.textColor = Theme.Colors.separatorOnContentBackgroundColor
        }
        
        private func setupLayout() {
            self.addSubview(self.containerView)
            self.containerView.addSubview(self.titleLabel)
            self.containerView.addSubview(self.amountLabel)
            
            self.titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            self.amountLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            
            self.titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            self.amountLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            
            self.containerView.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.top.bottom.equalToSuperview().inset(14.0)
            }
            
            self.titleLabel.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().inset(20.0)
                make.centerY.equalToSuperview()
            }
            
            self.amountLabel.snp.makeConstraints { (make) in
                make.leading.equalTo(self.titleLabel.snp.trailing).offset(10.0)
                make.firstBaseline.equalTo(self.titleLabel.snp.firstBaseline)
                make.trailing.equalToSuperview().inset(20.0)
            }
        }
    }
}
