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
}

extension SendPaymentAmount {
    typealias DisplayLogic = SendPaymentDisplayLogic
    
    class ViewController: UIViewController {
        
        typealias Model = SendPaymentAmount.Model
        typealias Event = SendPaymentAmount.Event
        
        // MARK: - Private properties
        
        private let stackView: ScrollableStackView = ScrollableStackView()
        
        private let balanceView: BalanceView = BalanceView()
        private let enterAmountView: EnterAmountView = EnterAmountView()
        private let descritionTextView: DescriptionTextView = DescriptionTextView()
        private let actionButton: UIButton = UIButton()
        
        private let disposeBag = DisposeBag()
        
        private let buttonHeight: CGFloat = 45.0
        
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
            self.setupStackView()
            self.setupBalanceView()
            self.setupEnterAmountView()
            self.setupDescriptionTextView()
            self.setupActionButton()
            self.setupLayout()
            
            self.observeKeyboard()
            
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
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
        
        private func setupStackView() {
            self.stackView.backgroundColor = Theme.Colors.contentBackgroundColor
            self.stackView.stackViewsSpacing = 10.0
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
        
        private func observeKeyboard() {
            let keyboardObserver = KeyboardObserver(
                self,
                keyboardWillChange: { (attributes) in
                    let keyboardHeight = attributes.heightIn(view: self.view)
                    if attributes.showingIn(view: self.view) {
                        self.actionButton.snp.remakeConstraints { (make) in
                            make.leading.trailing.equalToSuperview()
                            make.bottom.equalTo(self.view.safeArea.bottom).inset(keyboardHeight)
                            make.height.equalTo(self.buttonHeight)
                        }
                    } else {
                        self.actionButton.snp.remakeConstraints { (make) in
                            make.leading.trailing.equalToSuperview()
                            make.bottom.equalTo(self.view.safeArea.bottom)
                            make.height.equalTo(self.buttonHeight)
                        }
                    }
                    
                    UIView.animate(withKeyboardAttributes: attributes, animations: {
                        self.view.layoutIfNeeded()
                    })
            })
            KeyboardController.shared.add(observer: keyboardObserver)
        }
        
        private func setupLayout() {
            self.view.addSubview(self.stackView)
            self.view.addSubview(self.descritionTextView)
            self.view.addSubview(self.actionButton)
            
            self.stackView.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.centerY.equalTo(self.view.safeArea.centerY)
                make.height.equalTo(300)
            }
            
            self.stackView.insert(views: [
                self.balanceView,
                self.enterAmountView
                ]
            )
            
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
        let options: [String] = viewModel.balances.map({ $0.asset })
        self.routing?.onPresentPicker(Localized(.select_asset), options, { [weak self] (selectedIndex) in
            let balance = viewModel.balances[selectedIndex]
            let request = Event.BalanceSelected.Request(balanceId: balance.balanceId)
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
}
