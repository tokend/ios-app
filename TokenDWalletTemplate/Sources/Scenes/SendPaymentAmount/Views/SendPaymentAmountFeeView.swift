import UIKit

extension SendPaymentAmount {
    class FeeView: UIView {
        
        // MARK: - Public properties
        
        public var fee: String? {
            get { return self.feeLabel.text }
            set { self.feeLabel.text = newValue }
        }
        
        // MARK: - Private properties
        
        private let feeLabel: UILabel = UILabel()
        
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
            self.setupFeeLabel()
            self.setupLayout()
        }
        
        // MARK: - Public
        
        // MARK: - Private
        
        private func setupView() {
            self.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupFeeLabel() {
            self.feeLabel.backgroundColor = Theme.Colors.contentBackgroundColor
            self.feeLabel.font = Theme.Fonts.smallTextFont
            self.feeLabel.text = Localized(.no_fees)
            self.feeLabel.textColor = Theme.Colors.separatorOnContentBackgroundColor
        }
        
        private func setupLayout() {
            self.addSubview(self.feeLabel)
            
            self.feeLabel.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.top.bottom.equalToSuperview().inset(5.0)
            }
        }
    }
}
