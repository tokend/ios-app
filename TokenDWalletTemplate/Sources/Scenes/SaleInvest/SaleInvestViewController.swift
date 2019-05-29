import UIKit
import RxCocoa
import RxSwift

public protocol SaleInvestDisplayLogic: class {
    typealias Event = SaleInvest.Event
    
    func displaySceneUpdated(viewModel: Event.SceneUpdated.ViewModel)
    func displaySelectBalance(viewModel: Event.SelectBalance.ViewModel)
    func displayBalanceSelected(viewModel: Event.BalanceSelected.ViewModel)
    func displayInvestAction(viewModel: Event.InvestAction.ViewModel)
    func displayCancelInvestAction(viewModel: Event.CancelInvestAction.ViewModel)
    func displayError(viewModel: Event.Error.ViewModel)
}

extension SaleInvest {
    public typealias DisplayLogic = SaleInvestDisplayLogic
    
    @objc(SaleInvestViewController)
    public class ViewController: UIViewController {
        
        public typealias Event = SaleInvest.Event
        public typealias Model = SaleInvest.Model
        
        // MARK: - Private properties
        
        private let disposeBag = DisposeBag()
        
        private let containerView: UIView = UIView()
        
        private let titleLabel: UILabel = UILabel()
        private let investContenView: UIView = UIView()
        private let investButton: UIButton = UIButton()
        private let cancelButton: UIButton = UIButton()
        
        // Invest content views
        private var amountEditingContext: TextEditingContext<Decimal>?
        private let valueValidator = DecimalMaxValueValidator(maxValue: nil)
        private let amountField: TextFieldView = SharedViewsBuilder.createTextFieldView()
        private let selectAssetButton: UIButton = UIButton()
        private let availableAssetAmountLabel: UILabel = UILabel()
        
        private let sideInset: CGFloat = 20
        private let topInset: CGFloat = 15
        private let bottomInset: CGFloat = 15
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        private var onDeinit: DeinitCompletion = nil
        
        public func inject(
            interactorDispatch: InteractorDispatch?,
            routing: Routing?,
            onDeinit: DeinitCompletion = nil
            ) {
            
            self.interactorDispatch = interactorDispatch
            self.routing = routing
            self.onDeinit = onDeinit
        }
        
        // MARK: - Overridden
        
        public override func viewDidLoad() {
            super.viewDidLoad()
            
            self.commonInit()
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        // MARK: - Private
        
        private func commonInit() {
            self.setupView()
            self.setupContainerView()
            self.setupTitleLabel()
            self.setupInvestContenView()
            self.setupAvailableAssetAmountLabel()
            self.setupAmountTextField()
            self.setupInvestButton()
            self.setupCancelButton()
            self.setupSelectAssetButton()
            
            self.setupLayout()
        }
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.containerBackgroundColor
        }
        
        private func setupContainerView() {
            self.containerView.backgroundColor = Theme.Colors.contentBackgroundColor
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
            self.titleLabel.text = Localized(.investing)
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
            self.amountField.placeholder = Localized(.amount)
            self.amountField.textColor = Theme.Colors.textOnContentBackgroundColor
            self.amountField.invalidTextColor = Theme.Colors.negativeAmountColor
            self.amountField.onShouldReturn = { fieldView in
                _ = fieldView.resignFirstResponder()
                return false
            }
            
            let valueFormatter = PrecisedFormatter()
            valueFormatter.emptyZeroValue = true
            
            self.amountEditingContext = TextEditingContext(
                textInputView: self.amountField,
                valueFormatter: valueFormatter,
                valueValidator: self.valueValidator,
                callbacks: TextEditingContext.Callbacks(
                    onInputValue: { [weak self] (value) in
                        let requset = Event.EditAmount.Request(amount: value)
                        self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                            businessLogic.onEditAmount(request: requset)
                        })
                })
            )
        }
        
        private func setupCancelButton() {
            self.cancelButton.backgroundColor = Theme.Colors.contentBackgroundColor
            self.cancelButton.titleLabel?.font = Theme.Fonts.plainTextFont
            self.cancelButton.setTitle(
                Localized(.cancel_investment),
                for: .normal
            )
            self.cancelButton.setTitleColor(
                Theme.Colors.accentColor,
                for: .normal
            )
            
            self.cancelButton
                .rx
                .controlEvent(.touchUpInside)
                .asDriver()
                .drive(onNext: { [weak self] in
                    let onSelected: ((Int) -> Void) = { _ in
                        let request = Event.CancelInvestAction.Request()
                        self?.interactorDispatch?.sendRequest { businessLogic in
                            businessLogic.onCancelInvestAction(request: request)
                        }
                    }
                    self?.routing?.showDialog(
                        Localized(.cancel_investment),
                        Localized(.are_you_sure_you_want_to_cancel_investment),
                        [Localized(.yes)],
                        onSelected
                    )
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupInvestButton() {
            SharedViewsBuilder.configureActionButton(self.investButton, title: Localized(.invest))
            self.investButton.contentEdgeInsets = UIEdgeInsets(
                top: 0.0, left: self.sideInset, bottom: 0.0, right: self.sideInset
            )
            self.investButton
                .rx
                .controlEvent(.touchUpInside)
                .asDriver()
                .drive(onNext: { [weak self] in
                    let requset = Event.InvestAction.Request()
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onInvestAction(request: requset)
                    })
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupSelectAssetButton() {
            self.selectAssetButton.setTitleColor(Theme.Colors.darkAccentColor, for: .normal)
            self.selectAssetButton.titleLabel?.font = Theme.Fonts.actionButtonFont
            self.selectAssetButton.contentEdgeInsets = UIEdgeInsets(
                top: 0.0, left: self.sideInset, bottom: 0.0, right: 0.0
            )
            self.selectAssetButton
                .rx
                .controlEvent(.touchUpInside)
                .asDriver()
                .drive(onNext: { [weak self] in
                    let requset = Event.SelectBalance.Request()
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onSelectBalance(request: requset)
                    })
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupLayout() {
            self.view.addSubview(self.containerView)
            self.containerView.addSubview(self.titleLabel)
            self.containerView.addSubview(self.investContenView)
            self.containerView.addSubview(self.investButton)
            self.containerView.addSubview(self.cancelButton)
            
            self.containerView.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalToSuperview().inset(self.topInset)
                make.bottom.lessThanOrEqualToSuperview()
            }
            
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
            
            self.cancelButton.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().inset(self.sideInset)
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

extension SaleInvest.ViewController: SaleInvest.DisplayLogic {
    
    public func displaySceneUpdated(viewModel: Event.SceneUpdated.ViewModel) {
        self.valueValidator.maxValue = viewModel.viewModel.maxInputAmount
        self.amountEditingContext?.setValue(viewModel.viewModel.inputAmount)
        self.availableAssetAmountLabel.text = viewModel.viewModel.availableAmount
        self.selectAssetButton.setTitle(viewModel.viewModel.selectedAsset, for: .normal)
        self.cancelButton.isHidden = !viewModel.viewModel.isCancellable
        self.investButton.setTitle(viewModel.viewModel.actionTitle, for: .normal)
    }
    
    public func displaySelectBalance(viewModel: Event.SelectBalance.ViewModel) {
        let options: [String] = viewModel.balances.map({ $0.asset })
        self.routing?.onPresentPicker(Localized(.select_asset), options, { [weak self] (selectedIndex) in
            let balance = viewModel.balances[selectedIndex]
            let request = Event.BalanceSelected.Request(balanceId: balance.balanceId)
            self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                businessLogic.onBalanceSelected(request: request)
            })
        })
    }
    
    public func displayBalanceSelected(viewModel: Event.BalanceSelected.ViewModel) {
        self.valueValidator.maxValue = viewModel.viewModel.maxInputAmount
        self.amountEditingContext?.setValue(viewModel.viewModel.inputAmount)
        self.availableAssetAmountLabel.text = viewModel.viewModel.availableAmount
        self.selectAssetButton.setTitle(viewModel.viewModel.selectedAsset, for: .normal)
        self.cancelButton.isHidden = !viewModel.viewModel.isCancellable
        self.investButton.setTitle(viewModel.viewModel.actionTitle, for: .normal)
    }
    
    public func displayInvestAction(viewModel: Event.InvestAction.ViewModel) {
        switch viewModel {
            
        case .loading:
            self.routing?.onShowProgress()
            
        case .loaded:
            self.routing?.onHideProgress()
            
        case .failed(let message):
            self.routing?.onShowError(message)
            
        case .succeeded(let saleInvestModel):
            self.routing?.onSaleInvestAction(saleInvestModel)
        }
    }
    
    public func displayCancelInvestAction(viewModel: Event.CancelInvestAction.ViewModel) {
        switch viewModel {
            
        case .loading:
            self.routing?.onShowProgress()
            
        case .succeeded:
            self.routing?.onHideProgress()
            
        case .failed(let message):
            self.routing?.onHideProgress()
            self.routing?.onShowError(message)
        }
    }
    
    public func displayError(viewModel: Event.Error.ViewModel) {
        self.routing?.onShowError(viewModel.message)
    }
}
