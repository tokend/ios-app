import UIKit
import RxSwift

protocol SendPaymentDisplayLogic: class {
    
    typealias Event = SendPaymentAmount.Event
    
    func displayViewDidLoad(viewModel: Event.ViewDidLoad.ViewModel)
    func displayLoadBalances(viewModel: Event.LoadBalances.ViewModel)
    func displaySelectBalance(viewModel: Event.SelectBalance.ViewModel)
    func displayBalanceSelected(viewModel: Event.BalanceSelected.ViewModel)
    func displayEditAmount(viewModel: Event.EditAmount.ViewModel)
    func displayPaymentAction(viewModel: Event.PaymentAction.ViewModel)
    func displayWithdrawAction(viewModel: Event.WithdrawAction.ViewModel)
    func displayFeeOverviewAvailability(viewModel: Event.FeeOverviewAvailability.ViewModel)
    func displayFeeOverviewAction(viewModel: Event.FeeOverviewAction.ViewModel)
}

extension SendPaymentAmount {
    typealias DisplayLogic = SendPaymentDisplayLogic
    
    class ViewController: UIViewController {
        
        typealias Model = SendPaymentAmount.Model
        typealias Event = SendPaymentAmount.Event
        
        // MARK: - Private properties
        
        private let containerView: UIView = UIView()
        private let inputAmountContainer: UIView = UIView()
        
        private let recipientLabel: UILabel = UILabel()
        private let balanceView: BalanceView = BalanceView()
        private let enterAmountView: EnterAmountView = EnterAmountView()
        private let descritionTextView: DescriptionTextView = DescriptionTextView()
        private let actionButton: UIButton = UIButton()
        private let feesAction: UIBarButtonItem = UIBarButtonItem(
            title: Localized(.fees),
            style: .plain,
            target: nil,
            action: nil
        )
        
        private let disposeBag = DisposeBag()
        
        private let buttonHeight: CGFloat = 45.0
        
        private var viewDidAppear: Bool = false
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var viewConfig: Model.ViewConfig?
        private var routing: Routing?
        
        func inject(
            interactorDispatch: InteractorDispatch?,
            viewConfig: Model.ViewConfig?,
            routing: Routing?
            ) {
            
            self.interactorDispatch = interactorDispatch
            self.viewConfig = viewConfig
            self.routing = routing
        }
        
        // MARK: - Overridden
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.setupView()
            self.setupRecipientLabel()
            self.setupContainerView()
            self.setupInputAmountContainer()
            self.setupBalanceView()
            self.setupEnterAmountView()
            self.setupDescriptionTextView()
            self.setupActionButton()
            self.setupFeesAction()
            self.setupLayout()
            
            self.observeKeyboard()
            
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
            self.viewDidAppear = true
            
            let request = Event.LoadBalances.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onLoadBalances(request: request)
            }
        }
        
        // MARK: - Private
        
        private func updateWithSceneModel(_ sceneModel: Model.SceneViewModel) {
            self.balanceView.set(
                amount: sceneModel.selectedBalance?.balance,
                asset: sceneModel.selectedBalance?.asset
            )
            
            self.enterAmountView.set(amount: sceneModel.amount, asset: sceneModel.selectedBalance?.asset)
            
            self.updateAmountValid(sceneModel.amountValid)
        }
        
        private func updateAmountValid(_ amountValid: Bool) {
            self.balanceView.set(balanceHighlighted: !amountValid)
            self.enterAmountView.set(amountHighlighted: !amountValid)
        }
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupRecipientLabel() {
            self.recipientLabel.backgroundColor = Theme.Colors.contentBackgroundColor
            self.recipientLabel.font = Theme.Fonts.plainTextFont
            self.recipientLabel.textAlignment = .center
            self.recipientLabel.numberOfLines = 1
            self.recipientLabel.lineBreakMode = .byTruncatingMiddle
        }
        
        private func setupContainerView() {
            self.containerView.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupInputAmountContainer() {
            self.inputAmountContainer.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupBalanceView() {
            
        }
        
        private func setupEnterAmountView() {
            self.enterAmountView.onEnterAmount = { [weak self] (amount) in
                let request = Event.EditAmount.Request(amount: amount ?? 0.0)
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onEditAmount(request: request)
                })
            }
            
            self.enterAmountView.onSelectAsset = { [weak self] in
                let request = Event.SelectBalance.Request()
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onSelectBalance(request: request)
                })
            }
        }
        
        private func setupDescriptionTextView() {
            guard let viewConfig = self.viewConfig else {
                return
            }
            if !viewConfig.descriptionIsHidden {
                self.descritionTextView.onEdit = { [weak self] (description) in
                    let request = Event.DescriptionUpdated.Request(description: description)
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onDescriptionUpdated(request: request)
                    })
                }
            } else {
                self.descritionTextView.isHidden = true
            }
        }
        
        private func setupActionButton() {
            if let attributedTitle = self.viewConfig?.actionButtonTitle {
                self.actionButton.setAttributedTitle(attributedTitle, for: .normal)
            }
            self.actionButton.backgroundColor = Theme.Colors.accentColor
            self.actionButton
                .rx
                .tap
                .asDriver()
                .drive(onNext: { [weak self] in
                    self?.view.endEditing(true)
                    let request = Event.SubmitAction.Request()
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onSubmitAction(request: request)
                    })
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupFeesAction() {
            self.feesAction
                .rx
                .tap
                .asDriver()
                .drive(onNext: { [weak self] (_) in
                    let request = Event.FeeOverviewAction.Request()
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onFeeOverviewAction(request: request)
                    })
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeKeyboard() {
            let keyboardObserver = KeyboardObserver(
                self,
                keyboardWillChange: { (attributes) in
                    let keyboardHeight = attributes.heightIn(view: self.view)
                    if attributes.showingIn(view: self.view) {
                        self.actionButton.snp.remakeConstraints { (make) in
                            make.leading.trailing.equalToSuperview()
                            make.bottom.equalToSuperview().inset(keyboardHeight)
                            make.height.equalTo(self.buttonHeight)
                        }
                    } else {
                        self.actionButton.snp.remakeConstraints { (make) in
                            make.leading.trailing.equalToSuperview()
                            make.bottom.equalTo(self.view.safeArea.bottom)
                            make.height.equalTo(self.buttonHeight)
                        }
                    }
                    
                    if self.viewDidAppear {
                        UIView.animate(withKeyboardAttributes: attributes, animations: {
                            self.view.layoutIfNeeded()
                        })
                    }
            })
            KeyboardController.shared.add(observer: keyboardObserver)
        }
        
        private func setupLayout() {
            self.view.addSubview(self.containerView)
            self.containerView.addSubview(self.inputAmountContainer)
            self.containerView.addSubview(self.recipientLabel)
            self.inputAmountContainer.addSubview(self.balanceView)
            self.inputAmountContainer.addSubview(self.enterAmountView)
            self.view.addSubview(self.descritionTextView)
            self.view.addSubview(self.actionButton)
            
            self.containerView.snp.makeConstraints { (make) in
                make.leading.trailing.top.equalToSuperview()
                make.bottom.equalTo(self.descritionTextView.snp.top)
            }
            
            self.recipientLabel.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(20.0)
                make.top.equalToSuperview().inset(15.0)
            }
            
            self.inputAmountContainer.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.centerY.equalToSuperview()
            }
            
            self.balanceView.snp.makeConstraints { (make) in
                make.leading.trailing.top.equalToSuperview()
            }
            
            self.enterAmountView.snp.makeConstraints { (make) in
                make.leading.trailing.bottom.equalToSuperview()
                make.top.equalTo(self.balanceView.snp.bottom).offset(15.0)
            }
            
            self.descritionTextView.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.bottom.equalTo(self.actionButton.snp.top)
            }
            self.actionButton.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.bottom.equalTo(self.view.safeArea.bottom)
                make.height.equalTo(self.buttonHeight)
            }
        }
    }
}

// MARK: - DisplayLogic

extension SendPaymentAmount.ViewController: SendPaymentAmount.DisplayLogic {
    
    func displayViewDidLoad(viewModel: Event.ViewDidLoad.ViewModel) {
        self.recipientLabel.text = viewModel.recipientInfo
        self.updateWithSceneModel(viewModel.sceneModel)
    }
    
    func displayLoadBalances(viewModel: Event.LoadBalances.ViewModel) {
        switch viewModel {
            
        case .loading:
            self.routing?.onShowProgress()
            
        case .loaded:
            self.routing?.onHideProgress()
            
        case .failed(let errorMessage):
            self.routing?.onShowError(errorMessage)
            
        case .succeeded(let sceneModel):
            self.updateWithSceneModel(sceneModel)
        }
    }
    
    func displaySelectBalance(viewModel: Event.SelectBalance.ViewModel) {
        let assets: [String] = viewModel.balances.map({ $0.asset })
        self.routing?.onPresentPicker(assets, { [weak self] (balanceId) in
            let request = Event.BalanceSelected.Request(balanceId: balanceId)
            self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                businessLogic.onBalanceSelected(request: request)
            })
        })
    }
    
    func displayBalanceSelected(viewModel: Event.BalanceSelected.ViewModel) {
        self.updateWithSceneModel(viewModel.sceneModel)
    }
    
    func displayEditAmount(viewModel: Event.EditAmount.ViewModel) {
        self.updateAmountValid(viewModel.amountValid)
    }
    
    func displayPaymentAction(viewModel: Event.PaymentAction.ViewModel) {
        switch viewModel {
        case .loading:
            self.routing?.onShowProgress()
            
        case .loaded:
            self.routing?.onHideProgress()
            
        case .failed(let errorMessage):
            self.routing?.onShowError(errorMessage)
            
        case .succeeded(let sendModel):
            self.routing?.onSendAction?(sendModel)
        }
    }
    
    func displayWithdrawAction(viewModel: Event.WithdrawAction.ViewModel) {
        switch viewModel {
        case .loading:
            self.routing?.onShowProgress()
            
        case .loaded:
            self.routing?.onHideProgress()
            
        case .failed(let errorMessage):
            self.routing?.onShowError(errorMessage)
            
        case .succeeded(let sendModel):
            self.routing?.onHideProgress()
            self.routing?.onShowWithdrawDestination?(sendModel)
        }
    }
    
    func displayFeeOverviewAvailability(viewModel: Event.FeeOverviewAvailability.ViewModel) {
        if viewModel.available {
            self.navigationItem.rightBarButtonItem = self.feesAction
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
    }
    
    func displayFeeOverviewAction(viewModel: Event.FeeOverviewAction.ViewModel) {
        self.routing?.showFeesOverview(viewModel.asset, viewModel.feeType)
    }
}
