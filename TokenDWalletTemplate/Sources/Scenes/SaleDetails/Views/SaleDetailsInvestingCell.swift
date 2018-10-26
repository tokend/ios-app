import RxCocoa
import RxSwift
import SnapKit
import UIKit

extension SaleDetails {
    
    enum InvestingCell {
        
        struct ViewModel: CellViewModel {
            
            let availableAmount: String
            let inputAmount: Decimal
            let maxInputAmount: Decimal
            let selectedAsset: String?
            let identifier: CellIdentifier
            
            func setup(cell: InvestingCell.View) {
                cell.availableAmount = self.availableAmount
                cell.inputAmount = self.inputAmount
                cell.maxInputAmount = self.maxInputAmount
                cell.selectedAsset = self.selectedAsset
                cell.identifier = self.identifier
            }
        }
        
        class View: UITableViewCell {
            
            typealias DidSelectButton = (_ cellIdentifier: CellIdentifier) -> Void
            
            // MARK: - Public properties
            
            public var onInvestAction: DidSelectButton?
            public var onSelectBalance: DidSelectButton?
            public var onDidEnterAmount: ((_ value: Decimal?) -> Void)?
            
            public var inputAmount: Decimal? {
                get { return self.amountEditingContext?.value }
                set { self.amountEditingContext?.setValue(newValue) }
            }
            
            public var maxInputAmount: Decimal = 0.0 {
                didSet {
                    self.valueValidator.maxValue = self.maxInputAmount
                    self.amountEditingContext?.setValue(self.amountEditingContext?.value)
                }
            }
            
            public var availableAmount: String? {
                get { return self.availableAssetAmountLabel.text }
                set { self.availableAssetAmountLabel.text = newValue}
            }
            
            public var selectedAsset: String? {
                get { return self.selectAssetButton.title(for: .normal) }
                set { self.selectAssetButton.setTitle(newValue, for: .normal) }
            }
            
            public var identifier: CellIdentifier?
            
            // MARK: - Private properties
            
            private let disposeBag = DisposeBag()
            
            private let titleLabel: UILabel = UILabel()
            private let investContenView: UIView = UIView()
            private let investButton: UIButton = UIButton()
            
            // Invest content views
            private var amountEditingContext: TextEditingContext<Decimal>?
            private let valueValidator = DecimalMaxValueValidator(maxValue: nil)
            private let amountField: TextFieldView = SharedViewsBuilder.createTextFieldView()
            private let selectAssetButton: UIButton = UIButton()
            private let availableAssetAmountLabel: UILabel = UILabel()
            
            private let sideInset: CGFloat = 20
            private let topInset: CGFloat = 15
            private let bottomInset: CGFloat = 15
            
            // MARK: - Initializers
            
            override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)
                
                self.commonInit()
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            // MARK: - Private
            
            private func commonInit() {
                self.setupView()
                self.setupTitleLabel()
                self.setupInvestContenView()
                self.setupAvailableAssetAmountLabel()
                self.setupAmountTextField()
                self.setupInvestButton()
                self.setupSelectAssetButton()
                
                self.setupLayout()
            }
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.contentBackgroundColor
                self.selectionStyle = .none
            }
            
            private func setupSeparatorView(separator: UIView) {
                separator.backgroundColor = Theme.Colors.separatorOnContentBackgroundColor
                separator.isUserInteractionEnabled = false
            }
            
            private func setupTitleLabel() {
                self.titleLabel.font = Theme.Fonts.largeTitleFont
                self.titleLabel.textColor = Theme.Colors.textOnContentBackgroundColor
                self.titleLabel.textAlignment = .left
                self.titleLabel.numberOfLines = 1
                self.titleLabel.text = "Investing"
            }
            
            private func setupInvestContenView() {
                self.investContenView.backgroundColor = UIColor.clear
            }
            
            private func setupAvailableAssetAmountLabel() {
                self.availableAssetAmountLabel.font = Theme.Fonts.smallTextFont
                self.availableAssetAmountLabel.textColor = Theme.Colors.sideTextOnContainerBackgroundColor
                self.availableAssetAmountLabel.textAlignment = .left
                self.availableAssetAmountLabel.numberOfLines = 1
            }
            
            private func setupAmountTextField() {
                self.amountField.placeholder = "Amount"
                self.amountField.textColor = Theme.Colors.textOnContentBackgroundColor
                self.amountField.invalidTextColor = Theme.Colors.negativeAmountColor
                self.amountField.onShouldReturn = { fieldView in
                    _ = fieldView.resignFirstResponder()
                    return false
                }
                
                let valueFormatter = DecimalFormatter()
                valueFormatter.emptyZeroValue = true
                
                self.amountEditingContext = TextEditingContext(
                    textInputView: self.amountField,
                    valueFormatter: valueFormatter,
                    valueValidator: self.valueValidator,
                    callbacks: TextEditingContext.Callbacks(
                        onInputValue: { [weak self] (value) in
                            self?.onDidEnterAmount?(value)
                    })
                )
            }
            
            private func setupInvestButton() {
                SharedViewsBuilder.configureActionButton(self.investButton, title: "INVEST")
                self.investButton.contentEdgeInsets = UIEdgeInsets(
                    top: 0.0, left: self.sideInset, bottom: 0.0, right: self.sideInset
                )
                self.investButton
                    .rx
                    .controlEvent(.touchUpInside)
                    .asDriver()
                    .drive(onNext: { [weak self] in
                        guard let identifier = self?.identifier else {
                            return
                        }
                        
                        self?.onInvestAction?(identifier)
                    })
                    .disposed(by: self.disposeBag)
            }
            
            private func setupSelectAssetButton() {
                self.selectAssetButton.setTitleColor(Theme.Colors.mainColor, for: .normal)
                self.selectAssetButton.titleLabel?.font = Theme.Fonts.actionButtonFont
                self.selectAssetButton.contentEdgeInsets = UIEdgeInsets(
                    top: 0.0, left: self.sideInset, bottom: 0.0, right: 0.0
                )
                self.selectAssetButton
                    .rx
                    .controlEvent(.touchUpInside)
                    .asDriver()
                    .drive(onNext: { [weak self] in
                        guard let identifier = self?.identifier else {
                            return
                        }
                        
                        self?.onSelectBalance?(identifier)
                    })
                    .disposed(by: self.disposeBag)
            }
            
            private func setupLayout() {
                self.contentView.addSubview(self.titleLabel)
                self.contentView.addSubview(self.investContenView)
                self.contentView.addSubview(self.investButton)
                
                self.titleLabel.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalToSuperview().inset(self.topInset)
                }
                
                self.investContenView.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalTo(self.titleLabel.snp.bottom)
                }
                
                self.layoutInvestContenViews()
                
                self.investButton.snp.makeConstraints { (make) in
                    make.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalTo(self.investContenView.snp.bottom)
                    make.bottom.equalToSuperview().inset(self.bottomInset)
                    make.height.equalTo(44.0)
                }
            }
            
            private func layoutInvestContenViews() {
                let separator: UIView = UIView()
                self.setupSeparatorView(separator: separator)
                
                self.investContenView.addSubview(self.amountField)
                self.investContenView.addSubview(separator)
                self.investContenView.addSubview(self.availableAssetAmountLabel)
                self.investContenView.addSubview(self.selectAssetButton)
                
                self.amountField.snp.makeConstraints { (make) in
                    make.leading.equalToSuperview()
                    make.top.equalToSuperview().inset(self.topInset)
                    make.height.equalTo(44.0)
                }
                
                separator.snp.makeConstraints { (make) in
                    make.leading.equalTo(self.amountField.snp.leading)
                    make.trailing.equalTo(self.amountField.snp.trailing)
                    make.top.equalTo(self.amountField.snp.bottom).offset(4.0)
                    make.height.equalTo(1)
                }
                
                self.availableAssetAmountLabel.snp.makeConstraints { (make) in
                    make.leading.equalTo(self.amountField.snp.leading)
                    make.trailing.equalTo(self.amountField.snp.trailing)
                    make.top.equalTo(separator.snp.bottom).offset(4.0)
                    make.bottom.equalToSuperview().inset(self.bottomInset)
                }
                
                self.selectAssetButton.snp.makeConstraints { (make) in
                    make.leading.equalTo(self.amountField.snp.trailing).offset(self.sideInset)
                    make.trailing.equalToSuperview()
                    make.centerY.equalTo(self.amountField)
                    make.width.equalTo(60)
                    make.height.equalTo(44.0)
                }
            }
        }
    }
}
