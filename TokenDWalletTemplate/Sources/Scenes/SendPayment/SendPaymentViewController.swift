import UIKit
import RxSwift

protocol SendPaymentDisplayLogic: class {
    
    typealias Event = SendPayment.Event
    
    func displayViewDidLoad(viewModel: Event.ViewDidLoad.ViewModel)
    func displayLoadBalances(viewModel: Event.LoadBalances.ViewModel)
    func displaySelectBalance(viewModel: Event.SelectBalance.ViewModel)
    func displayBalanceSelected(viewModel: Event.BalanceSelected.ViewModel)
    func displaySelectedContact(viewModel: Event.SelectedContact.ViewModel)
    func displayScanRecipientQRAddress(viewModel: Event.ScanRecipientQRAddress.ViewModel)
    func displayEditAmount(viewModel: Event.EditAmount.ViewModel)
    func displayPaymentAction(viewModel: Event.PaymentAction.ViewModel)
    func displayWithdrawAction(viewModel: Event.WithdrawAction.ViewModel)
}

extension SendPayment {
    typealias DisplayLogic = SendPaymentDisplayLogic
    
    class ViewController: UIViewController {
        
        typealias Model = SendPayment.Model
        typealias Event = SendPayment.Event
        
        // MARK: - Private properties
        
        private let stackView: ScrollableStackView = ScrollableStackView()
        
        private let balanceView: BalanceView = BalanceView()
        private let recipientAddressView: RecipientAddressView = RecipientAddressView()
        private let enterAmountView: EnterAmountView = EnterAmountView()
        
        private let disposeBag = DisposeBag()
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        private var viewConfig: Model.ViewConfig?
        
        func inject(
            interactorDispatch: InteractorDispatch?,
            routing: Routing?,
            viewConfig: Model.ViewConfig
            ) {
            
            self.interactorDispatch = interactorDispatch
            self.routing = routing
            self.viewConfig = viewConfig
        }
        
        // MARK: - Overridden
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.setupStackView()
            self.setupBalanceView()
            self.setupRecipientAddressView()
            self.setupEnterAmountView()
            self.setupSendPaymentButton()
            self.setupLayout()
            
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
            
            self.recipientAddressView.address = sceneModel.recipientAddress
            
            self.enterAmountView.set(amount: sceneModel.amount, asset: sceneModel.selectedBalance?.asset)
            
            self.updateAmountValid(sceneModel.amountValid)
        }
        
        private func updateAmountValid(_ amountValid: Bool) {
            self.balanceView.set(balanceHighlighted: !amountValid)
            self.enterAmountView.set(amountHighlighted: !amountValid)
        }
        
        private func setupStackView() {
            
        }
        
        private func setupBalanceView() {
            
        }
        
        private func setupRecipientAddressView() {
            if let viewConfig = self.viewConfig {
                self.recipientAddressView.title = viewConfig.recipientAddressFieldTitle
                self.recipientAddressView.placeholder = viewConfig.recipientAddressFieldPlaceholder
            }
            
            self.recipientAddressView.onAddressEdit = { [weak self] (address) in
                let request = Event.EditRecipientAddress.Request(address: address)
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onEditRecipientAddress(request: request)
                })
            }
            
            self.recipientAddressView.onQRAction = { [weak self] in
                self?.routing?.onPresentQRCodeReader({ result in
                    let request = Event.ScanRecipientQRAddress.Request(qrResult: result)
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onScanRecipientQRAddress(request: request)
                    })
                })
            }
            
            self.recipientAddressView.onSelectAccount = { [weak self] in
                self?.routing?.onSelectContactEmail({ [weak self] (email) in
                    let request = Event.SelectedContact.Request(email: email)
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onSelectedContact(request: request)
                    })
                })
            }
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
        
        private func setupSendPaymentButton() {
            let button = UIBarButtonItem(image: #imageLiteral(resourceName: "Checkmark"), style: .plain, target: nil, action: nil)
            button.rx
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
            self.navigationItem.rightBarButtonItem = button
        }
        
        private func setupLayout() {
            self.view.addSubview(self.stackView)
            
            self.stackView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            
            self.stackView.insert(views: [
                self.balanceView,
                self.recipientAddressView,
                self.enterAmountView
                ]
            )
        }
    }
}

// MARK: - DisplayLogic

extension SendPayment.ViewController: SendPayment.DisplayLogic {
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
    
    func displaySelectedContact(viewModel: Event.SelectedContact.ViewModel) {
        self.updateWithSceneModel(viewModel.sceneModel)
    }
    
    func displayScanRecipientQRAddress(viewModel: Event.ScanRecipientQRAddress.ViewModel) {
        switch viewModel {
            
        case .canceled:
            break
            
        case .failed(let errorMessage):
            self.routing?.onShowError(errorMessage)
            
        case .succeeded(let sceneViewModel):
            self.updateWithSceneModel(sceneViewModel)
        }
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
            self.routing?.onSendWithdraw?(sendModel)
        }
    }
}
