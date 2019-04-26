import UIKit
import RxSwift
import RxCocoa

extension CreateOffer {
    class EnterAmountView: UIView {
        
        // MARK: - Public properties
        
        public var onEnterAmount: ((_ amount: Decimal?) -> Void)?
        public var title: String? {
            get { return self.titleLabel.text }
            set { self.titleLabel.text = newValue }
        }
        public var placeholder: String? {
            get { return self.amountField.placeholder }
            set { self.amountField.placeholder = newValue }
        }
        public var asset: String? {
            get { return self.assetLabel.text }
            set { self.assetLabel.text = newValue }
        }
        public var amount: Decimal? {
            get { return self.amountEditingContext?.value }
            set { self.amountEditingContext?.setValue(newValue) }
        }
        
        // MARK: - Private properties
        
        private let titleLabel: UILabel = UILabel()
        private let amountField: TextFieldView = SharedViewsBuilder.createTextFieldView()
        private var amountEditingContext: TextEditingContext<Decimal>?
        private let assetLabel: UILabel = UILabel()
        
        private let disposeBag = DisposeBag()
        
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
            self.setupAmountField()
            self.setupAssetLabel()
            self.setupLayout()
        }
        
        // MARK: - Public
        
        func set(amountHighlighted: Bool) {
            self.amountField.textColor = amountHighlighted
                ? Theme.Colors.negativeColor
                : Theme.Colors.textOnContentBackgroundColor
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupTitleLabel() {
            self.titleLabel.text = Localized(.amount)
            self.titleLabel.font = Theme.Fonts.textFieldTitleFont
            self.titleLabel.textAlignment = .left
            self.titleLabel.textColor = Theme.Colors.textOnContentBackgroundColor
        }
        
        private func setupAmountField() {
            self.amountField.onShouldReturn = { fieldView in
                _ = fieldView.resignFirstResponder()
                return false
            }
            let valueFormatter = PrecisedFormatter()
            valueFormatter.emptyZeroValue = true
            
            self.amountEditingContext = TextEditingContext(
                textInputView: self.amountField,
                valueFormatter: valueFormatter,
                callbacks: TextEditingContext.Callbacks(
                    onInputValue: { [weak self] (value) in
                        self?.onEnterAmount?(value)
                })
            )
        }
        
        private func setupAssetLabel() {
            self.assetLabel.text = Localized(.asset)
            self.assetLabel.font = Theme.Fonts.textFieldTitleFont
            self.assetLabel.textAlignment = .right
            self.assetLabel.textColor = Theme.Colors.textOnContentBackgroundColor
        }
        
        private func setupLayout() {
            self.addSubview(self.titleLabel)
            self.addSubview(self.amountField)
            self.addSubview(self.assetLabel)
            
            self.titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            self.amountField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            self.assetLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            self.titleLabel.setContentHuggingPriority(.required, for: .horizontal)
            self.amountField.setContentHuggingPriority(.defaultLow, for: .horizontal)
            self.assetLabel.setContentHuggingPriority(.required, for: .horizontal)
            
            self.titleLabel.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().inset(20.0)
                make.centerY.equalToSuperview()
                make.top.bottom.equalToSuperview().inset(14.0)
            }
            
            self.assetLabel.snp.makeConstraints { (make) in
                make.top.bottom.equalToSuperview()
                make.trailing.equalToSuperview().inset(20.0)
            }
            
            self.amountField.snp.makeConstraints { (make) in
                make.leading.equalTo(self.titleLabel.snp.trailing).offset(10.0)
                make.centerY.equalTo(self.titleLabel)
                make.trailing.equalTo(self.assetLabel.snp.leading).offset(-5.0)
            }
        }
    }
}
