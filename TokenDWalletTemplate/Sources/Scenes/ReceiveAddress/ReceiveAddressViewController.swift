import UIKit

protocol ReceiveAddressDisplayLogic: class {
    func displayViewDidLoadSync(viewModel: ReceiveAddress.Event.ViewDidLoadSync.ViewModel)
    func displayValueActionsChanged(viewModel: ReceiveAddress.Event.ValueActionsChanged.ViewModel)
    func displayQRCodeRegenerated(viewModel: ReceiveAddress.Event.QRCodeRegenerated.ViewModel)
    func displayValueChanged(viewModel: ReceiveAddress.Event.ValueChanged.ViewModel)
    func displayCopyAction(viewModel: ReceiveAddress.Event.CopyAction.ViewModel)
    func displayShareAction(viewModel: ReceiveAddress.Event.ShareAction.ViewModel)
}

extension ReceiveAddress {
    typealias DisplayLogic = ReceiveAddressDisplayLogic
    
    class ViewController: UIViewController {
        
        // MARK: - Public properties
        
        public var viewConfig: ReceiveAddress.Model.ViewConfig = ReceiveAddress.Model.ViewConfig(
            copiedLocalizationKey: "",
            tableViewTopInset: 0
            ) {
            didSet {
                guard self.isViewLoaded else {
                    return
                }
                self.updateWithViewConfig()
            }
        }
        
        // MARK: - Private properties
        
        private let tableView: BXFStaticTableView = BXFStaticTableView()
        private let defaultBottomInset: CGFloat = 24
        
        private lazy var qrContentView: QRCell = {
            let view = QRCell()
            view.onQRTap = { [weak self] in
                let request = ReceiveAddress.Event.CopyAction.Request()
                self?.interactorDispatch?.sendRequest { businessLogic in
                    businessLogic.onCopyAction(request: request)
                }
            }
            return view
        }()
        private lazy var qrSection: BXFStaticTableViewSection = {
            let section = BXFStaticTableViewSection(
                header: BXFStaticTableViewSectionHeaderFooterView.instantiate(with: .header, text: nil),
                cell: BXFStaticTableViewSectionCell.instantiate(with: self.qrContentView, border: false),
                footer: BXFStaticTableViewSectionHeaderFooterView.instantiate(with: .footer, text: nil))
            return section
        }()
        
        // MARK: - Injections
        
        var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        
        // MARK: - Public
        
        func inject(interactorDispatch: InteractorDispatch?, routing: Routing?) {
            self.interactorDispatch = interactorDispatch
            self.routing = routing
        }
        
        // MARK: - Overridden
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.setupTableView()
            self.addShareNavigationItem()
            self.setupLayout()
            self.updateWithViewConfig()
            
            let request = ReceiveAddress.Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { (businessLogic) in
                businessLogic.onViewDidLoad(request: request)
            }
            
            let syncRequest = ReceiveAddress.Event.ViewDidLoadSync.Request()
            self.interactorDispatch?.sendSyncRequest(requestBlock: { (businessLogic) in
                businessLogic.onViewDidLoadSync(request: syncRequest)
            })
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            let request = ReceiveAddress.Event.ViewWillAppear.Request()
            self.interactorDispatch?.sendRequest { (businessLogic) in
                businessLogic.onViewWillAppear(request: request)
            }
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            
            let qrSize = self.qrContentView.qrCodeSize
            let request =  ReceiveAddress.Event.ViewDidLayoutSubviews.Request(qrCodeSize: qrSize)
            self.interactorDispatch?.sendRequest { (businessLogic) in
                businessLogic.onViewDidLayoutSubviews(request: request)
            }
        }
        
        // MARK: - Private
        
        @objc private func doneToolbarItemAction() {
            self.view.endEditing(true)
        }
        
        private func updateWithViewConfig() {
            self.tableView.setTopInset(self.viewConfig.tableViewTopInset)
        }
        
        private func setupTableView() {
            self.tableView.backgroundColor = UIColor.white
        }
        
        private func setupLayout() {
            self.view.addSubview(tableView)
            self.tableView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            
            self.tableView.addSection(self.qrSection)
            self.tableView.layoutIfNeeded()
        }
        
        private func updateValue(_ value: String) {
            self.qrContentView.valueLabelText = value
        }
        
        private func addShareNavigationItem() {
            var items: [UIBarButtonItem] = []
            
            let shareItem = UIBarButtonItem(
                image: Assets.shareIcon.image,
                style: .plain,
                target: self,
                action: #selector(self.shareReceiveAddressRequest)
            )
            items.append(shareItem)
            
            self.navigationItem.rightBarButtonItems = items
        }
        
        @objc private func copyReceiveAddressRequest() {
            let request = ReceiveAddress.Event.CopyAction.Request()
            self.interactorDispatch?.sendRequest { (businessLogic) in
                businessLogic.onCopyAction(request: request)
            }
        }
        
        @objc private func shareReceiveAddressRequest() {
            let request = ReceiveAddress.Event.ShareAction.Request()
            self.interactorDispatch?.sendRequest { (businessLogic) in
                businessLogic.onShareAction(request: request)
            }
        }
    }
}

extension ReceiveAddress.ViewController: ReceiveAddress.DisplayLogic {
    func displayViewDidLoadSync(viewModel: ReceiveAddress.Event.ViewDidLoadSync.ViewModel) {
        self.updateValue(viewModel.address)
        self.qrContentView.numberOfLinesInValue = viewModel.valueLinesNumber
    }
    
    func displayValueActionsChanged(viewModel: ReceiveAddress.Event.ValueActionsChanged.ViewModel) {
        let copyAction = viewModel.availableValueActions.first(where: { (action) -> Bool in
            return action.valueAction == .copy
        })
        if let action = copyAction {
            self.qrContentView.copyActionTitle = action.title
            self.qrContentView.copyAction = (() -> Void)? { [weak self] in
                self?.copyReceiveAddressRequest()
            }
        } else {
            self.qrContentView.copyAction = nil
        }
        
        let shareAction = viewModel.availableValueActions.first(where: { (action) -> Bool in
            return action.valueAction == .share
        })
        if let action = shareAction {
            self.qrContentView.shareActionTitle = action.title
            
            self.qrContentView.shareAction = (()->Void)? { [weak self] in
                self?.shareReceiveAddressRequest()
            }
        } else {
            self.qrContentView.shareAction = nil
        }
    }
    
    func displayQRCodeRegenerated(viewModel: ReceiveAddress.Event.QRCodeRegenerated.ViewModel) {
        self.qrContentView.setQRImage(viewModel.qrCode, animated: true)
    }
    
    func displayValueChanged(viewModel: ReceiveAddress.Event.ValueChanged.ViewModel) {
        self.updateValue(viewModel.value)
    }
    
    func displayCopyAction(viewModel: ReceiveAddress.Event.CopyAction.ViewModel) {
        self.routing?.onCopy(viewModel.stringToCopy)
        self.qrContentView.showTemporaryTextAndDisableTapGesture(self.viewConfig.copiedLocalizationKey)
    }
    
    func displayShareAction(viewModel: ReceiveAddress.Event.ShareAction.ViewModel) {
        self.routing?.onShare(viewModel.itemsToShare)
    }
}
