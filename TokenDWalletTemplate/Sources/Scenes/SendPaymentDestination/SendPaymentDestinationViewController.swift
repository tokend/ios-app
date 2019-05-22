import UIKit
import RxSwift

public protocol SendPaymentDestinationDisplayLogic: class {
    typealias Event = SendPaymentDestination.Event
    
    func displayContactsUpdated(viewModel: Event.ContactsUpdated.ViewModel)
    func displaySelectedContact(viewModel: Event.SelectedContact.ViewModel)
    func displayScanRecipientQRAddress(viewModel: Event.ScanRecipientQRAddress.ViewModel)
    func displayPaymentAction(viewModel: Event.PaymentAction.ViewModel)
    func displayWithdrawAction(viewModel: Event.WithdrawAction.ViewModel)
    func displayLoadingStatusDidChange(viewModel: Event.LoadingStatusDidChange.ViewModel)
}

extension SendPaymentDestination {
    public typealias DisplayLogic = SendPaymentDestinationDisplayLogic
    
    @objc(SendPaymentDestinationViewController)
    public class ViewController: UIViewController {
        
        public typealias Event = SendPaymentDestination.Event
        public typealias Model = SendPaymentDestination.Model
        
        // MARK: - Private properties
        
        private let actionTitle: UILabel = UILabel()
        private let recipientAddressView: RecipientAddressView = RecipientAddressView()
        private let tableView: UITableView = UITableView(frame: .zero, style: .grouped)
        private let actionButton: UIButton = UIButton()
        
        private let buttonHeight: CGFloat = 45.0
        private let disposeBag: DisposeBag = DisposeBag()
        
        private var sections: [SendPaymentDestination.Model.SectionViewModel] = []
        
        private var viewDidAppear: Bool = false
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var viewConfig: Model.ViewConfig?
        private var routing: Routing?
        private var onDeinit: DeinitCompletion = nil
        
        public func inject(
            interactorDispatch: InteractorDispatch?,
            viewConfig: Model.ViewConfig?,
            routing: Routing?,
            onDeinit: DeinitCompletion = nil
            ) {
            
            self.interactorDispatch = interactorDispatch
            self.viewConfig = viewConfig
            self.routing = routing
            self.onDeinit = onDeinit
        }
        
        // MARK: - Overridden
        
        public override func viewDidLoad() {
            super.viewDidLoad()
            
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                businessLogic.onViewDidLoad(request: request)
            })
            
            self.setupView()
            self.setupActionTitleLabel()
            self.setupRecipientAddressView()
            self.setupTableView()
            self.setupActionButton()
            self.setupLayout()
            
            self.observeKeyboard()
        }
        
        public override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
            self.viewDidAppear = true
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.containerBackgroundColor
        }
        
        private func setupActionTitleLabel() {
            self.actionTitle.backgroundColor = Theme.Colors.contentBackgroundColor
            self.actionTitle.font = Theme.Fonts.plainTextFont
            self.actionTitle.textAlignment = .center
            self.actionTitle.text = self.viewConfig?.actionTitle
        }
        
        private func setupRecipientAddressView() {
            self.recipientAddressView.placeholder = self.viewConfig?.recipientAddressFieldPlaceholder
            
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
        
        private func setupTableView() {
            guard let viewConfig = self.viewConfig,
                !viewConfig.contactsAreHidden else {
                    self.tableView.isHidden = true
                    return
            }
            
            self.tableView.backgroundColor = Theme.Colors.contentBackgroundColor
            self.tableView.register(classes: [
                SendPaymentDestination.ContactCell.ViewModel.self,
                SendPaymentDestination.EmptyCell.ViewModel.self
                ]
            )
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.tableView.separatorStyle = .none
        }
        
        private func setupActionButton() {
            self.actionButton.backgroundColor = Theme.Colors.accentColor
            self.actionButton
                .rx
                .tap
                .asDriver()
                .drive(onNext: { [weak self] (_) in
                    let request = Event.SubmitAction.Request()
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onSubmitAction(request: request)
                    })
                })
                .disposed(by: self.disposeBag)
            
            guard let viewConfig = self.viewConfig else {
                return
            }
            
            self.actionButton.setAttributedTitle(
                viewConfig.actionButtonTitle,
                for: .normal
            )
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
            self.view.addSubview(self.recipientAddressView)
            self.view.addSubview(self.tableView)
            self.view.addSubview(self.actionButton)
            
            self.recipientAddressView.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalToSuperview().inset(20.0)
            }
            
            self.tableView.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(self.recipientAddressView.snp.bottom).offset(20.0)
                make.bottom.equalTo(self.actionButton.snp.top).inset(10.0)
            }
            
            self.actionButton.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.bottom.equalTo(self.view.safeArea.bottom)
                make.height.equalTo(self.buttonHeight)
            }
        }
    }
}

extension SendPaymentDestination.ViewController: SendPaymentDestination.DisplayLogic {
    
    public func displayContactsUpdated(viewModel: Event.ContactsUpdated.ViewModel) {
            self.sections = viewModel.sections
            self.tableView.reloadData()
    }
    
    public func displaySelectedContact(viewModel: Event.SelectedContact.ViewModel) {
        switch viewModel {
            
        case .failure(let message):
            self.routing?.showError(message)
            
        case .success(let address):
            self.recipientAddressView.address = address
        }
    }
    
    public func displayScanRecipientQRAddress(viewModel: Event.ScanRecipientQRAddress.ViewModel) {
        switch viewModel {
            
        case .canceled:
            break
            
        case .failed(let errorMessage):
            self.routing?.showError(errorMessage)
            
        case .succeeded(let address):
            self.recipientAddressView.address = address
        }
    }
    
    public func displayPaymentAction(viewModel: Event.PaymentAction.ViewModel) {
        switch viewModel {
            
        case .destination(let model):
            self.routing?.showSendAmount(model)
            
        case .error(let message):
            self.routing?.showError(message)
        }
    }
    
    public func displayWithdrawAction(viewModel: Event.WithdrawAction.ViewModel) {
        switch viewModel {
            
        case .failed(let errorMessage):
            self.routing?.showError(errorMessage)
            
        case .succeeded(let model):
            self.routing?.showWithdrawConformation(model)
        }
    }
    
    public func displayLoadingStatusDidChange(viewModel: Event.LoadingStatusDidChange.ViewModel) {
        switch viewModel {
            
        case .loaded:
            self.routing?.hideProgress()
            
        case .loading:
            self.routing?.showProgress()
        }
    }
}

// MARK: - UITableViewDelegate

extension SendPaymentDestination.ViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = self.sections[indexPath.section].cells[indexPath.row]
        
        if let model = model as? SendPaymentDestination.ContactCell.ViewModel {
            let request = Event.SelectedContact.Request(email: model.email)
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                businessLogic.onSelectedContact(request: request)
            })
        }
    }
}

// MARK: - UITableViewDataSource

extension SendPaymentDestination.ViewController: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].cells.count
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section].title
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.sections[indexPath.section].cells[indexPath.row]
        let cell = tableView.dequeueReusableCell(with: model, for: indexPath)
        return cell
    }
}
