import UIKit
import DifferenceKit

public protocol SendConfirmationSceneDisplayLogic: AnyObject {
    
    typealias Event = SendConfirmationScene.Event
    
    func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel)
    func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel)
    func displayDidTapConfirmationSync(viewModel: Event.DidTapConfirmationSync.ViewModel)
}

extension SendConfirmationScene {
    
    public typealias DisplayLogic = SendConfirmationSceneDisplayLogic
    
    @objc(SendConfirmationSceneViewController)
    public class ViewController: BaseViewController {
        
        public typealias Event = SendConfirmationScene.Event
        public typealias Model = SendConfirmationScene.Model
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
        // MARK: - Private properties
        
        private let tableView: UITableView = .init(frame: .zero, style: .grouped)
        
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

private extension SendConfirmationScene.ViewController {
    
    func setup() {
        setupView()
        setupTableView()
        setupLayout()
    }
    
    func setupView() {
        navigationItem.title = Localized(.send_confirmation_title)
        view.backgroundColor = Theme.Colors.mainBackgroundColor
        
        navigationItem.setRightBarButton(
            .init(
                title: Localized(.send_confirmation_confirm),
                style: .plain,
                target: self,
                action: #selector(didTapConfirmation)
            ),
            animated: true
        )
    }
    
    @objc func didTapConfirmation() {
        let request: Event.DidTapConfirmationSync.Request = .init()
        interactorDispatch?.sendSyncRequest { (businessLogic) in
            businessLogic.onDidTapConfirmationSync(request: request)
        }
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.contentInset.bottom = 24.0
        
        tableView.register(
            classes: [
                SendConfirmationScene.InfoCell.ViewModel.self
            ]
        )
        
        tableView.register(
            classes: [
                CommonHeaderView.ViewModel.self
        ])
    }
    
    func setupLayout() {
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
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
    }
    
    func cell(for indexPath: IndexPath) -> CellViewAnyModel {
        sections[indexPath.section].cells[indexPath.row]
    }
}

// MARK: - UITableViewDataSource

extension SendConfirmationScene.ViewController: UITableViewDataSource {
    
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

// MARK: - UITableViewDelegate

extension SendConfirmationScene.ViewController: UITableViewDelegate {
    
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

extension SendConfirmationScene.ViewController: SendConfirmationScene.DisplayLogic {
    
    public func displaySceneDidUpdate(viewModel: Event.SceneDidUpdate.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
    
    public func displaySceneDidUpdateSync(viewModel: Event.SceneDidUpdateSync.ViewModel) {
        setup(with: viewModel.viewModel, animated: viewModel.animated)
    }
    
    public func displayDidTapConfirmationSync(viewModel: Event.DidTapConfirmationSync.ViewModel) {
        routing?.onConfirmation()
    }
}
