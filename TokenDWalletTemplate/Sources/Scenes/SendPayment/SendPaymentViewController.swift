import UIKit
import RxSwift

protocol SendPaymentDisplayLogic: class {
    func displayViewDidLoad(viewModel: SendPayment.Event.ViewDidLoad.ViewModel)
    func displayLoadBalances(viewModel: SendPayment.Event.LoadBalances.ViewModel)
    func displaySelectBalance(viewModel: SendPayment.Event.SelectBalance.ViewModel)
    func displayBalanceSelected(viewModel: SendPayment.Event.BalanceSelected.ViewModel)
    func displayScanRecipientQRAddress(viewModel: SendPayment.Event.ScanRecipientQRAddress.ViewModel)
    func displayEditAmount(viewModel: SendPayment.Event.EditAmount.ViewModel)
    func displayPaymentAction(viewModel: SendPayment.Event.PaymentAction.ViewModel)
    func displayWithdrawAction(viewModel: SendPayment.Event.WithdrawAction.ViewModel)
}

extension SendPayment {
    typealias DisplayLogic = SendPaymentDisplayLogic
    
    class ViewController: UIViewController {
        
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
            
            let request = SendPayment.Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
            let request = SendPayment.Event.LoadBalances.Request()
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
    func displayViewDidLoad(viewModel: SendPayment.Event.ViewDidLoad.ViewModel) {
        self.updateWithSceneModel(viewModel.sceneModel)
    }
    
    func displayLoadBalances(viewModel: SendPayment.Event.LoadBalances.ViewModel) {
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
    
    func displaySelectBalance(viewModel: SendPayment.Event.SelectBalance.ViewModel) {
        let options: [String] = viewModel.balances.map({ $0.asset })
        self.routing?.onPresentPicker("Select Asset", options, { [weak self] (selectedIndex) in
            let balance = viewModel.balances[selectedIndex]
            let request = SendPayment.Event.BalanceSelected.Request(balanceId: balance.balanceId)
            self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                businessLogic.onBalanceSelected(request: request)
            })
        })
    }
    
    func displayBalanceSelected(viewModel: SendPayment.Event.BalanceSelected.ViewModel) {
        self.updateWithSceneModel(viewModel.sceneModel)
    }
    
    func displayScanRecipientQRAddress(viewModel: SendPayment.Event.ScanRecipientQRAddress.ViewModel) {
        switch viewModel {
            
        case .canceled:
            break
            
        case .failed(let errorMessage):
            self.routing?.onShowError(errorMessage)
            
        case .succeeded(let sceneViewModel):
            self.updateWithSceneModel(sceneViewModel)
        }
    }
    
    func displayEditAmount(viewModel: SendPayment.Event.EditAmount.ViewModel) {
        self.updateAmountValid(viewModel.amountValid)
    }
    
    func displayPaymentAction(viewModel: SendPayment.Event.PaymentAction.ViewModel) {
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
    
    func displayWithdrawAction(viewModel: SendPayment.Event.WithdrawAction.ViewModel) {
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
