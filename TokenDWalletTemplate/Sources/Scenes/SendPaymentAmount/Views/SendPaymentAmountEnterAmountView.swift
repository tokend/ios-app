import UIKit
import RxCocoa
import RxSwift

extension SendPaymentAmount {
    class EnterAmountView: UIView {
        
        // MARK: - Public properties
        
        var onEnterAmount: ((_ amount: Decimal?) -> Void)?
        var onSelectAsset: (() -> Void)?
        
        // MARK: - Private properties
        
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
            self.setupAmountField()
            self.setupAssetButton()
            self.setupLayout()
        }
        
        // MARK: - Public
        
        func set(amount: Decimal?, asset: String?) {
            self.amountEditingContext?.setValue(amount)
            self.assetButton.setAttributedTitle(
                NSAttributedString(
                    string: asset ?? "",
                    attributes: [
                        .font: Theme.Fonts.largeTitleFont
                    ]),
                for: .normal
            )
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
        
        private func setupAmountField() {
            self.amountField.textAlignment = .right
            self.amountField.font =  Theme.Fonts.hugeTitleFont
            self.amountField.attributedPlaceholder = NSAttributedString(
                string: "0",
                attributes: [
                    .font: Theme.Fonts.hugeTitleFont,
                    .foregroundColor: Theme.Colors.textFieldForegroundColor
                ])
            self.amountField.keyboardType = .decimalPad
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
            
            _ = self.amountField.becomeFirstResponder()
        }
        
        private func setupAssetButton() {
            self.assetButton.tintColor = Theme.Colors.mainColor
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
            self.addSubview(self.amountField)
            self.addSubview(self.assetButton)
            
            self.amountField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            self.assetButton.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            self.amountField.setContentHuggingPriority(.defaultLow, for: .horizontal)
            self.assetButton.setContentHuggingPriority(.required, for: .horizontal)
            
            self.assetButton.contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 20.0, bottom: 0.0, right: 20.0)
            self.assetButton.snp.makeConstraints { (make) in
                make.top.bottom.equalToSuperview()
                make.leading.equalTo(self.amountField.snp.trailing)
                make.trailing.lessThanOrEqualToSuperview()
            }
            
            self.amountField.snp.makeConstraints { (make) in
                make.top.bottom.equalToSuperview().inset(5.0)
                make.leading.equalToSuperview().inset(10.0)
                make.trailing.greaterThanOrEqualTo(self.snp.centerX)
            }
        }
    }
}
