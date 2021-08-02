import UIKit
import DifferenceKit

public protocol SettingsSceneDisplayLogic: AnyObject {
    
    typealias Event = SettingsScene.Event
    
    func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel)
    func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel)
    func displayDidTapItemSync(viewModel: Event.DidTapItemSync.ViewModel)
}

extension SettingsScene {
    
    public typealias DisplayLogic = SettingsSceneDisplayLogic
    
    @objc(SettingsSceneViewController)
    public class ViewController: BaseViewController {
        
        public typealias Event = SettingsScene.Event
        public typealias Model = SettingsScene.Model
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
        // MARK: - Private properties
        
        private let tableView: UITableView = .init(frame: .zero, style: .grouped)
        private let refreshControl: UIRefreshControl = .init()
        
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
    }
}

// MARK: - Private methods

private extension SettingsScene.ViewController {
    
    func setup() {
        setupView()
        setupTableView()
        setupRefreshControl()
        setupLayout()
    }
    
    func setupView() {
        navigationItem.title = Localized(.settings_title)
        view.backgroundColor = Theme.Colors.mainBackgroundColor
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        
//        tableView.refreshControl = refreshControl
        
        tableView.register(
            classes: [
                IconTitleDisclosureCell.ViewModel.self,
                SettingsScene.SwitcherCell.ViewModel.self
            ]
        )
        
        tableView.register(
            classes: [
                HeaderFooterView.ViewModel.self
        ])
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
    
    func setupLayout() {
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeArea.top)
            make.leading.trailing.bottom.equalToSuperview()
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
        
        if sceneViewModel.isLoading {
            refreshControl.beginRefreshing()
        } else {
            refreshControl.endRefreshing()
        }
    }
    
    func cell(for indexPath: IndexPath) -> CellViewAnyModel {
        
        sections[indexPath.section].cells[indexPath.row]
    }
    
    func setTableViewCell(
        _ cell: SettingsScene.SwitcherCell.ViewModel,
        with id: String
    ) {

        if let indexPath = indexPathForSwitcherCell(with: cell.id) {
            sections[indexPath.section].cells[indexPath.row] = cell
        }
    }
    
    func indexPathForSwitcherCell(with id: String) -> IndexPath? {

        for section in 0..<sections.count {
            for row in 0..<sections[section].cells.count {

                if let oldViewModel = sections[section].cells[row] as? SettingsScene.SwitcherCell.ViewModel,
                   oldViewModel.id == id {

                    return .init(row: row, section: section)
                }
            }
        }

        return nil
    }
}

// MARK: UITableViewDataSource

extension SettingsScene.ViewController: UITableViewDataSource {
    
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
        
        let model = self.cell(for: indexPath)
        let cell = tableView.dequeueReusableCell(
            with: self.cell(for: indexPath),
            for: indexPath
        )
        
        if let switcherCell = cell as? SettingsScene.SwitcherCell.View,
           var switcherModel = model as? SettingsScene.SwitcherCell.ViewModel {
            
            switcherCell.onSwitched = { [weak self] (value) in
                
                switcherModel.switcherStatus = value
                self?.setTableViewCell(switcherModel, with: switcherModel.id)

                let request: Event.SwitcherValueDidChangeSync.Request = .init(id: switcherModel.id, newValue: value)
                self?.interactorDispatch?.sendSyncRequest { (businessLogic) in
                    businessLogic.onSwitcherValueDidChangeSync(request: request)
                }
            }
        }
        
        return cell
    }
}

// MARK: UITableViewDelegate

extension SettingsScene.ViewController: UITableViewDelegate {
    
    public func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        
        let tableViewWidth = tableView.bounds.width
        
        guard let height = (cell(for: indexPath) as? UITableViewCellHeightProvider)?.height(with: tableViewWidth)
            else { return UITableView.automaticDimension }
        
        if tableView.separatorStyle != .none && tableView.style == .grouped {
            return height + 1.0 / UIScreen.main.scale
        }
        
        return height
    }
    
    public func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        
        let cell = self.cell(for: indexPath)
        
        if let disclosureCell = cell as? IconTitleDisclosureCell.ViewModel {
            
            let request: Event.DidTapItemSync.Request = .init(id: disclosureCell.id)
            interactorDispatch?.sendSyncRequest { (businessLogic) in
                businessLogic.onDidTapItemSync(request: request)
            }
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
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        guard let viewModel = sections[section].footer
            else { return nil }
        
        return tableView.dequeueReusableHeaderFooterView(
            with: viewModel
        )
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        let tableViewWidth = tableView.bounds.width
        
        guard let viewModel = sections[section].footer
            else { return .leastNormalMagnitude }
        
        let heightProvider = viewModel as? UITableViewHeaderFooterViewHeightProvider
        
        guard let height = heightProvider?.height(with: tableViewWidth)
            else { return UITableView.automaticDimension }
        
        return height
    }
}

// MARK: - DisplayLogic

extension SettingsScene.ViewController: SettingsScene.DisplayLogic {
    
    public func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
    
    public func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
    
    public func displayDidTapItemSync(viewModel: Event.DidTapItemSync.ViewModel) {
        
        switch viewModel.item {
        
        case .language:
            routing?.onLanguageTap()
        case .accountId:
            routing?.onAccountIdTap()
        case .verification:
            routing?.onVerificationTap()
        case .secretSeed:
            routing?.onSecretSeedTap()
        case .signOut:
            routing?.onSignOutTap()
        case .changePassword:
            routing?.onChangePasswordTap()
            
        case .lockApp,
             .biometrics,
             .tfa:
            break
        }
    }
}
