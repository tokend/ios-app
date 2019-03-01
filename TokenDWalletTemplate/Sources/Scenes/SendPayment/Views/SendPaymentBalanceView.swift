import UIKit

extension SendPayment {
    class BalanceView: UIView {
        
        // MARK: - Public properties
        
        // MARK: - Private properties
        
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
        }
        
        func set(balanceHighlighted: Bool) {
            self.amountLabel.textColor = balanceHighlighted
                ? Theme.Colors.negativeColor
                : Theme.Colors.textOnContentBackgroundColor
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupTitleLabel() {
            self.titleLabel.text = Localized(.balance_colon)
            SharedViewsBuilder.configureInputForm(titleLabel: self.titleLabel)
        }
        
        private func setupAmountLabel() {
            SharedViewsBuilder.configureInputForm(valueLabel: self.amountLabel)
        }
        
        private func setupLayout() {
            self.addSubview(self.titleLabel)
            self.addSubview(self.amountLabel)
            
            self.titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            self.amountLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            
            self.titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            self.amountLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            
            self.titleLabel.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().inset(20.0)
                make.centerY.equalToSuperview()
                make.top.bottom.equalToSuperview().inset(14.0)
            }
            
            self.amountLabel.snp.makeConstraints { (make) in
                make.leading.equalTo(self.titleLabel.snp.trailing).offset(10.0)
                make.firstBaseline.equalTo(self.titleLabel.snp.firstBaseline)
                make.trailing.equalToSuperview().inset(20.0)
            }
        }
    }
}
