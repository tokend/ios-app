import UIKit
import RxSwift

protocol AuthenticatorAuthDisplayLogic: class {
    typealias Event = AuthenticatorAuth.Event
    
    func displayActionButtonClicked(viewModel: Event.ActionButtonClicked.ViewModel)
    func displaySetupActionButton(viewModel: Event.SetupActionButton.ViewModel)
    func displayUpdateQRContent(viewModel: Event.UpdateQRContent.ViewModel)
    func displayFetchedAuthResult(viewModel: Event.FetchedAuthResult.ViewModel)
}

extension AuthenticatorAuth {
    typealias DisplayLogic = AuthenticatorAuthDisplayLogic
    
    class ViewController: UIViewController {
        
        typealias Event = AuthenticatorAuth.Event
        typealias Model = AuthenticatorAuth.Model
        
        // MARK: - Private properties
        
        private let tableView: BXFStaticTableView = BXFStaticTableView()
        private let defaultBottomInset: CGFloat = 24
        private let disposeBag = DisposeBag()
        
        private lazy var qrContentView: QRCell = {
            let view = QRCell()
            return view
        }()
        private lazy var qrSection: BXFStaticTableViewSection = {
            let section = BXFStaticTableViewSection(
                header: BXFStaticTableViewSectionHeaderFooterView.instantiate(with: .header, text: nil),
                cell: BXFStaticTableViewSectionCell.instantiate(with: self.qrContentView, border: false),
                footer: BXFStaticTableViewSectionHeaderFooterView.instantiate(with: .footer, text: nil))
            return section
        }()
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        private var onDeinit: DeinitCompletion = nil
        
        func inject(
            interactorDispatch: InteractorDispatch?,
            routing: Routing?,
            onDeinit: DeinitCompletion = nil
            ) {
            
            self.interactorDispatch = interactorDispatch
            self.routing = routing
            self.onDeinit = onDeinit
        }
        
        // MARK: - Overridden
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.setupView()
            self.setupTableView()
            self.setupLayout()
            
            let request = Event.ViewDidLoad.Request(qrSize: self.qrContentView.qrCodeSize)
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.containerBackgroundColor
        }
        
        private func setupTableView() {
            self.tableView.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupLayout() {
            self.view.addSubview(self.tableView)
            self.tableView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            
            self.tableView.addSection(self.qrSection)
            self.tableView.layoutIfNeeded()
        }
        
        private func addButton(title: String) {
            let actionButtonView = ActionCell()
                actionButtonView.onActionButtonClicked = { [weak self] in
                    let request = Event.ActionButtonClicked.Request()
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onActionButtonClicked(request: request)
                    })
                }
            actionButtonView.actionTitle = title
            
            let actionButtonSection = BXFStaticTableViewSection(
                    header: BXFStaticTableViewSectionHeaderFooterView.instantiate(with: .header, text: nil),
                    cell: BXFStaticTableViewSectionCell.instantiate(with: actionButtonView, border: false),
                    footer: BXFStaticTableViewSectionHeaderFooterView.instantiate(with: .footer, text: nil)
            )
         
            self.tableView.addSection(actionButtonSection)
            self.tableView.layoutIfNeeded()
        }
    }
}

extension AuthenticatorAuth.ViewController: AuthenticatorAuth.DisplayLogic {
    
    func displayActionButtonClicked(viewModel: Event.ActionButtonClicked.ViewModel) {
        guard let url = viewModel.url else {
            return
        }
        self.routing?.openUrl(url)
    }
    
    func displaySetupActionButton(viewModel: Event.SetupActionButton.ViewModel) {
        switch viewModel.state {
            
        case .accessable(let title):
            self.addButton(title: title)
            
        case .inaccessable:
            self.qrContentView.valueLabelText = Localized(.scan_qr_code_via_authenticator)
        }
    }
    
    func displayUpdateQRContent(viewModel: Event.UpdateQRContent.ViewModel) {
        self.qrContentView.setQRImage(viewModel.qrImage, animated: true)
    }
    
    func displayFetchedAuthResult(viewModel: Event.FetchedAuthResult.ViewModel) {
        switch viewModel.result {
            
        case .failure(let message):
            self.routing?.showError(message)
            
        case .success(let account):
            self.routing?.onSuccessfulSignIn(account)
        }
    }
}
