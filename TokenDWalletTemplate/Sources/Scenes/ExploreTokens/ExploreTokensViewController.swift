import UIKit

protocol ExploreTokensDisplayLogic: class {
    func displayTokensDidChange(viewModel: ExploreTokensScene.Event.TokensDidChange.ViewModel)
    func displayLoadingStatusDidChange(viewModel: ExploreTokensScene.Event.LoadingStatusDidChange.ViewModel)
    func displayDidSelectAction(viewModel: ExploreTokensScene.Event.DidSelectAction.ViewModel)
    func displayError(viewModel: ExploreTokensScene.Event.Error.ViewModel)
}

extension ExploreTokensScene {
    typealias DisplayLogic = ExploreTokensDisplayLogic
    
    class ViewController: UIViewController {
        
        // MARK: - Private properties
        
        private let searchController: UISearchController = UISearchController(searchResultsController: nil)
        private let emptyLabel: UILabel = SharedViewsBuilder.createEmptyLabel()
        private let tableView: UITableView = UITableView(frame: .zero, style: .grouped)
        private let refreshControl: UIRefreshControl = UIRefreshControl()
        
        private var sections: [Model.TableSection] = []
        
        private let defaultBottomInset: CGFloat = 32
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        
        func inject(interactorDispatch: InteractorDispatch?, routing: Routing?) {
            self.interactorDispatch = interactorDispatch
            self.routing = routing
        }
        
        // MARK: - Overridden
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.setupView()
            self.setupEmptyLabel()
            self.setupSearchController()
            self.setupRefreshControl()
            self.setupTableView()
            
            self.setupLayout()
            
            self.addKeyboardObserver()
            
            let request = ExploreTokensScene.Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                let request = ExploreTokensScene.Event.ViewDidAppear.Request()
                businessLogic.onViewDidAppear(request: request)
            })
        }
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                let request = ExploreTokensScene.Event.ViewWillDisappear.Request()
                businessLogic.onViewWillDisappear(request: request)
            })
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.containerBackgroundColor
            if #available(iOS 11, *) {
                self.navigationItem.searchController = self.searchController
                self.navigationItem.hidesSearchBarWhenScrolling = true
                self.definesPresentationContext = true
            }
        }
        
        private func setupSearchController() {
            self.searchController.searchBar.placeholder = Localized(.search)
            self.searchController.searchResultsUpdater = self
            self.searchController.obscuresBackgroundDuringPresentation = false
            self.searchController.dimsBackgroundDuringPresentation = false
            self.searchController.hidesNavigationBarDuringPresentation = false
            
            if #available(iOS 11, *) {
                let searchBar = self.searchController.searchBar
                searchBar.tintColor = Theme.Colors.contentBackgroundColor
                searchBar.barTintColor = Theme.Colors.contentBackgroundColor
                
                if let textField = searchBar.value(forKey: "searchField") as? UITextField {
                    if let backgroundView = textField.subviews.first {
                        backgroundView.backgroundColor = Theme.Colors.contentBackgroundColor
                        backgroundView.layer.cornerRadius = 10
                        backgroundView.clipsToBounds = true
                    }
                }
            }
        }
        
        private func setupEmptyLabel() { }
        
        private func setupTableView() {
            self.tableView.backgroundColor = UIColor.clear
            self.tableView.keyboardDismissMode = .onDrag
            self.tableView.register(classes: [ExploreTokensTableViewCell.Model.self])
            self.tableView.dataSource = self
            self.tableView.delegate = self
            self.tableView.rowHeight = UITableView.automaticDimension
            self.tableView.estimatedRowHeight = 125
            self.tableView.separatorStyle = .none
            
            if #available(iOS 11, *) { } else {
                self.tableView.tableHeaderView = self.searchController.searchBar
            }
            
            self.tableView.refreshControl = self.refreshControl
        }
        
        private func setupRefreshControl() {
            if #available(iOS 11, *) {
                self.refreshControl.tintColor = Theme.Colors.textOnAccentColor
            }
            self.refreshControl.addTarget(self, action: #selector(self.refreshAction), for: .valueChanged)
        }
        
        private func setupLayout() {
            self.view.addSubview(self.emptyLabel)
            self.view.addSubview(self.tableView)
            
            self.emptyLabel.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
                make.leading.top.greaterThanOrEqualToSuperview().inset(15)
                make.trailing.bottom.lessThanOrEqualToSuperview().inset(15)
            }
            
            self.tableView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
        
        private func reloadTableView() {
            self.tableView.reloadData()
        }
        
        // MARK: Refresh
        
        @objc private func refreshAction() {
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                let request = ExploreTokensScene.Event.DidInitiateRefresh.Request()
                businessLogic.onDidInitiateRefresh(request: request)
            })
        }
        
        private func showRefresh(animated: Bool) {
            self.revealRefreshControlIfNeeded(animated: animated)
            self.beginRefreshing()
        }
        
        private func beginRefreshing() {
            self.refreshControl.beginRefreshing()
        }
        
        private func hideRefresh(animated: Bool) {
            guard self.refreshControl.isRefreshing
                else {
                    return
            }
            self.endRefreshing()
            self.hideRefreshControlIfNeeded(animated: animated)
        }
        
        private func endRefreshing() {
            self.refreshControl.endRefreshing()
        }
        
        private func revealRefreshControlIfNeeded(animated: Bool) {
            if self.tableView.contentOffset.y <= 0 {
                self.revealRefreshControl(animated: animated)
            }
        }
        
        private func revealRefreshControl(animated: Bool) {
            self.setOffset(withRefreshControl: true, animated: animated)
        }
        
        private func hideRefreshControlIfNeeded(animated: Bool) {
            if self.tableView.contentOffset.y <= 0 {
                self.hideRefreshControl(animated: animated)
            }
        }
        
        private func hideRefreshControl(animated: Bool) {
            self.setOffset(withRefreshControl: false, animated: animated)
        }
        
        private func setOffset(withRefreshControl: Bool, animated: Bool) {
            guard !self.tableView.isDecelerating,
                !self.tableView.isTracking,
                !self.tableView.isDragging
                else {
                    return
            }
            
            var oldOffset = self.tableView.contentOffset
            if withRefreshControl {
                oldOffset.y -= self.refreshControl.frame.height
            }
            self.tableView.setContentOffset(oldOffset, animated: animated)
        }
        
        private func addKeyboardObserver() {
            let keyboardObserver = KeyboardObserver(self) { [weak self] (attributes) in
                self?.setBottomInsetWithKeyboardAttributes(attributes)
            }
            KeyboardController.shared.add(observer: keyboardObserver)
        }
        
        private func setBottomInsetWithKeyboardAttributes(
            _ attributes: KeyboardAttributes?
            ) {
            
            let keyboardHeightInTableView: CGFloat = attributes?.heightInContainerView(
                self.view,
                view: self.tableView
                ) ?? 0
            var bottomInset: CGFloat = self.defaultBottomInset + keyboardHeightInTableView
            if attributes?.showingIn(view: self.view) != true {
                if #available(iOS 11, *) {
                    bottomInset += self.view.safeAreaInsets.bottom
                } else {
                    bottomInset += self.bottomLayoutGuide.length
                }
            }
            self.tableView.contentInset.bottom = bottomInset
        }
    }
}

extension ExploreTokensScene.ViewController: ExploreTokensScene.DisplayLogic {
    func displayTokensDidChange(viewModel: ExploreTokensScene.Event.TokensDidChange.ViewModel) {
        switch viewModel {
            
        case .empty(let title):
            self.sections = []
            self.emptyLabel.text = title
            self.emptyLabel.isHidden = false
            
        case .sections(let sections):
            self.sections = sections
            self.emptyLabel.isHidden = true
        }
        self.reloadTableView()
    }
    
    func displayLoadingStatusDidChange(viewModel: ExploreTokensScene.Event.LoadingStatusDidChange.ViewModel) {
        switch viewModel {
        case .loaded:
            self.hideRefresh(animated: true)
        case .loading:
            self.showRefresh(animated: true)
        }
    }
    
    func displayDidSelectAction(viewModel: ExploreTokensScene.Event.DidSelectAction.ViewModel) {
        switch viewModel {
        case .viewHistory(let identifier):
            self.routing?.onDidSelectHistoryForBalance(identifier)
        }
    }
    
    func displayError(viewModel: ExploreTokensScene.Event.Error.ViewModel) {
        self.routing?.onError(viewModel.message)
    }
}

extension ExploreTokensScene.ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = self.sections[indexPath.section].cells[indexPath.row]
        self.routing?.onDidSelectToken(model.identifier)
    }
}

extension ExploreTokensScene.ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].cells.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.sections[indexPath.section].cells[indexPath.row]
        let cell = tableView.dequeueReusableCell(with: model, for: indexPath)
        if let cell = cell as? ExploreTokensTableViewCell.View {
            cell.onActionButtonClicked = { [weak self] (_) in
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    let request = ExploreTokensScene.Event.DidSelectAction.Request(identifier: model.identifier)
                    businessLogic.onDidSelectAction(request: request)
                })
            }
        }
        return cell
    }
}

extension ExploreTokensScene.ViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let filter = searchController.searchBar.text ?? ""
        self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
            let request = ExploreTokensScene.Event.DidFilter.Request(filter: filter)
            businessLogic.onDidFilter(request: request)
        })
    }
}
