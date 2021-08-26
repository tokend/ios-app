import UIKit
import DifferenceKit

public protocol BalanceDetailsSceneDisplayLogic: AnyObject {
    
    typealias Event = BalanceDetailsScene.Event
    
    func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel)
    func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel)
}

extension BalanceDetailsScene {
    
    public typealias DisplayLogic = BalanceDetailsSceneDisplayLogic
    
    @objc(BalanceDetailsSceneViewController)
    public class ViewController: BaseViewController {
        
        public typealias Event = BalanceDetailsScene.Event
        public typealias Model = BalanceDetailsScene.Model
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
        // MARK: - Private properties
        
        private var toolbarHeight: CGFloat { 44.0 }
        
        private let balanceView: BalanceView = .init()
        private let tableView: UITableView = .init()
        private let refreshControl: UIRefreshControl = .init()
        private let toolbar: UIToolbar = .init()
        
        private var sections: [Model.Section] = []
        
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
            
            setup()
            
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }

            let requestSync = Event.ViewDidLoadSync.Request()
            self.interactorDispatch?.sendSyncRequest { businessLogic in
                businessLogic.onViewDidLoadSync(request: requestSync)
            }
        }
        
        public override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            
            updateTableHeaderViewHeight()
        }
    }
}

// MARK: - Private methods

private extension BalanceDetailsScene.ViewController {
    
    func setup() {
        setupView()
        setupNavigationBar()
        setupBalanceView()
        setupTableView()
        setupRefreshControl()
        setupToolbar()
        
        setupLayout()
    }
    
    func setupView() {
        view.backgroundColor = .white
    }
    
    func setupNavigationBar() {
        navigationController?.navigationBar.setBackgroundImage(.init(), for: .default)
        navigationController?.navigationBar.shadowImage = .init()
    }
    
    func setupBalanceView() { }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        
        tableView.contentInset.bottom = toolbarHeight
        tableView.scrollIndicatorInsets.bottom = toolbarHeight
        tableView.tableFooterView = .init(frame: .init(x: 0.0, y: 0.0, width: 0.0, height: 1.0))
        
        tableView.refreshControl = refreshControl
        
        tableView.register(
            classes: [
                BalanceDetailsScene.TransactionCell.ViewModel.self
            ]
        )
    }
    
    func setupRefreshControl() {
        refreshControl.addTarget(
            self,
            action: #selector(refreshControlValueChanged),
            for: .valueChanged
        )
    }
    
    @objc func refreshControlValueChanged() {
        interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
            let request: Event.DidRefresh.Request = .init()
            businessLogic.onDidRefresh(request: request)
        })
    }
    
    func setupToolbar() {
        
        let buyItem: UIBarButtonItem = .init(
            image: Assets.buy_toolbar_icon.image,
            style: .plain,
            target: self,
            action: #selector(toolbarDisabledAction)
        )
        buyItem.isEnabled = false
        let receiveItem: UIBarButtonItem = .init(
            image: Assets.receive_toolbar_icon.image,
            style: .plain,
            target: self,
            action: #selector(toolbarReceiveAction)
        )
        let sendItem: UIBarButtonItem = .init(
            image: Assets.send_toolbar_icon.image,
            style: .plain,
            target: self,
            action: #selector(toolbarSendAction)
        )
        let depositItem: UIBarButtonItem = .init(
            image: Assets.deposit_toolbar_icon.image,
            style: .plain,
            target: self,
            action: #selector(toolbarDisabledAction)
        )
        depositItem.isEnabled = false
        let withdrawItem: UIBarButtonItem = .init(
            image: Assets.withdraw_toolbar_icon.image,
            style: .plain,
            target: self,
            action: #selector(toolbarDisabledAction)
        )
        withdrawItem.isEnabled = false
        
        toolbar.items = [
            .init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            buyItem,
            .init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            receiveItem,
            .init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            sendItem,
            .init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            depositItem,
            .init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            withdrawItem,
            .init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
        ]
    }
    
    @objc func toolbarDisabledAction() { }
    
    @objc func toolbarReceiveAction() {
        routing?.onReceive()
    }
    
    @objc func toolbarSendAction() {
        routing?.onSend()
    }
    
    func setupLayout() {
        tableView.tableHeaderView = balanceView
        view.addSubview(tableView)
        view.addSubview(toolbar)
        
        tableView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        toolbar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeArea.bottom)
            make.height.equalTo(toolbarHeight)
        }
    }
    
    func setup(
        with sceneViewModel: Model.SceneViewModel,
        animated: Bool
    ) {
        
        switch sceneViewModel.content {
        
        case .empty:
            
            self.sections = []
            tableView.reloadData()
            
        case .content(let sections):
            
            if animated {
                let changeSet = StagedChangeset(source: self.sections, target: sections)
                if !changeSet.isEmpty {
                    self.tableView.reload(
                        using: changeSet,
                        deleteSectionsAnimation: .fade,
                        insertSectionsAnimation: .fade,
                        reloadSectionsAnimation: .none,
                        deleteRowsAnimation: .fade,
                        insertRowsAnimation: .fade,
                        reloadRowsAnimation: .none,
                        setData: { [weak self] (newSections) in
                            self?.sections = newSections
                        })
                } else {
                    self.sections = sections
                }
            } else {
                self.sections = sections
                tableView.reloadData()
            }
        }
        
        balanceView.balance = sceneViewModel.balance
        balanceView.exchangeValue = sceneViewModel.rate
        balanceView.icon = sceneViewModel.balanceIcon
        balanceView.abbreviation = sceneViewModel.balanceNameAbbreviation
        balanceView.title = sceneViewModel.assetName
        
        if sceneViewModel.isLoading {
            refreshControl.beginRefreshing()
        } else {
            refreshControl.endRefreshing()
        }
        
        updateTableHeaderViewHeight()
    }
    
    func cell(for indexPath: IndexPath) -> CellViewAnyModel {
        
        sections[indexPath.section].cells[indexPath.row]
    }
    
    func updateTableHeaderViewHeight() {
        guard let headerView = tableView.tableHeaderView else {
            return
        }
        
        let size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        
        if headerView.frame.size.height != size.height {
            headerView.frame.size.height = size.height
            
            tableView.tableHeaderView = headerView
            tableView.layoutIfNeeded()
        }
    }
}

// MARK: UITableViewDataSource

extension BalanceDetailsScene.ViewController: UITableViewDataSource {
    
    public func numberOfSections(
        in tableView: UITableView
    ) -> Int {
        sections.count
    }
    
    public func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        sections[section].cells.count
    }
    
    public func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(
            with: self.cell(for: indexPath),
            for: indexPath
        )
        
        return cell
    }
}

// MARK: UITableViewDelegate

extension BalanceDetailsScene.ViewController: UITableViewDelegate {
    
    public func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        
        let tableViewWidth = tableView.bounds.width
        
        guard let height = (cell(for: indexPath) as? UITableViewCellHeightProvider)?.height(with: tableViewWidth)
            else { return UITableView.automaticDimension }
        
        return height
    }
    
    public func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        
        let cell = self.cell(for: indexPath)
        
        if let transaction = cell as? BalanceDetailsScene.TransactionCell.ViewModel {
            routing?.onDidSelectTransaction(transaction.id)
        }
    }
    
    public func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        
        guard let viewModel = sections[section].header
            else { return nil }
        
        return tableView.dequeueReusableHeaderFooterView(
            with: viewModel
        )
    }
    
    public func tableView(
        _ tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat {
        
        let tableViewWidth = tableView.bounds.width
        
        guard let viewModel = sections[section].header
            else { return .leastNormalMagnitude }
        
        let heightProvider = viewModel as? UITableViewHeaderFooterViewHeightProvider
        
        guard let height = heightProvider?.height(with: tableViewWidth)
            else { return UITableView.automaticDimension }
        
        return height
    }
}

// MARK: - DisplayLogic

extension BalanceDetailsScene.ViewController: BalanceDetailsScene.DisplayLogic {
    
    public func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
    
    public func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
}
