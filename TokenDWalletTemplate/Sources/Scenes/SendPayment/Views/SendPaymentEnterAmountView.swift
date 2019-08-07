import UIKit
import RxCocoa
import RxSwift

extension SendPayment {
    class EnterAmountView: UIView {
        
        // MARK: - Public properties
        
        var onEnterAmount: ((_ amount: Decimal?) -> Void)?
        var onSelectAsset: (() -> Void)?
        
        // MARK: - Private properties
        
        private let titleLabel: UILabel = UILabel()
        private let amountField: TextFieldView = SharedViewsBuilder.createTextFieldView()
        private var amountEditingContext: TextEditingContext<Decimal>?
        private let assetButton: UIButton = UIButton(type: .system)
        
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
            self.setupAssetButton()
            self.setupLayout()
        }
        
        // MARK: - Public
        
        func set(amount: Decimal?, asset: String?) {
            self.amountEditingContext?.setValue(amount)
            self.assetButton.setTitle(asset, for: .normal)
        }
        
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
            self.titleLabel.text = "Amount:"
            self.titleLabel.font = Theme.Fonts.textFieldTitleFont
            self.titleLabel.textAlignment = .left
            self.titleLabel.textColor = Theme.Colors.textOnContentBackgroundColor
        }
        
        private func setupAmountField() {
            self.amountField.placeholder = "Enter amount"
            self.amountField.onShouldReturn = { fieldView in
                _ = fieldView.resignFirstResponder()
                return false
            }
            let valueFormatter = DecimalFormatter()
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
        
        private func setupAssetButton() {
            self.assetButton
                .rx
                .controlEvent(.touchUpInside)
                .asDriver()
                .drive(onNext: { [weak self] in
                    self?.onSelectAsset?()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupLayout() {
            self.addSubview(self.titleLabel)
            self.addSubview(self.amountField)
            self.addSubview(self.assetButton)
            
            self.titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            self.amountField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            self.assetButton.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            self.titleLabel.setContentHuggingPriority(.required, for: .horizontal)
            self.amountField.setContentHuggingPriority(.defaultLow, for: .horizontal)
            self.assetButton.setContentHuggingPriority(.required, for: .horizontal)
            
            self.titleLabel.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().inset(20.0)
                make.centerY.equalToSuperview()
                make.top.bottom.equalToSuperview().inset(14.0)
            }
            
            self.assetButton.contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 20.0, bottom: 0.0, right: 20.0)
            self.assetButton.snp.makeConstraints { (make) in
                make.top.bottom.equalToSuperview()
                make.trailing.equalToSuperview()
            }
            
            self.amountField.snp.makeConstraints { (make) in
                make.leading.equalTo(self.titleLabel.snp.trailing).offset(10.0)
                make.centerY.equalTo(self.titleLabel)
                make.trailing.equalTo(self.assetButton.snp.leading).offset(-5.0)
            }
        }
    }
}
