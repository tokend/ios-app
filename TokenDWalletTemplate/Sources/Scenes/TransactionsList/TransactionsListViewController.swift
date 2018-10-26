import UIKit

protocol TransactionsListSceneDisplayLogic: class {
    func displayTransactionsDidUpdate(viewModel: TransactionsListScene.Event.TransactionsDidUpdate.ViewModel)
    func displayLoadingStatusDidChange(viewModel: TransactionsListScene.Event.LoadingStatusDidChange.ViewModel)
    func displayHeaderTitleDidChange(viewModel: TransactionsListScene.Event.HeaderTitleDidChange.ViewModel)
}

protocol TransactionsListSceneProtocol {
    typealias ContentSize = CGSize
    typealias ContentSizeDidChange = (ContentSize) -> Void
    
    var asset: String { get set }
    var onContentSizeDidChange: ContentSizeDidChange? { get set }
    var contentSize: ContentSize { get }
}

extension TransactionsListScene {
    typealias DisplayLogic = TransactionsListSceneDisplayLogic
    
    class ViewController: UIViewController, TransactionsListSceneProtocol {
        
        // MARK: - Private properties
        
        private let emptyLabel: UILabel = SharedViewsBuilder.createEmptyLabel()
        private let tableView: UITableView = UITableView(frame: .zero, style: .plain)
        private let stickyHeader: TableViewStickyHeader = TableViewStickyHeader()
        private let refreshControl: UIRefreshControl = UIRefreshControl()
        private var sections: [Model.SectionViewModel] = []
        private var oldPanTranslation: CGFloat = 0
        private var oldContentOffset: CGFloat = 0
        private var minimumContentInset: CGFloat = 0
        
        // MARK: -
        
        var asset: String = "" {
            didSet {
                self.interactorDispatch?.sendRequest(requestBlock: { [weak self] (businessLogic) in
                    guard let asset = self?.asset else { return }
                    let request = TransactionsListScene.Event.AssetDidChange.Request(asset: asset)
                    businessLogic.onAssetDidChange(request: request)
                })
            }
        }
        var contentSize: ContentSize {
            return self.tableView.contentSize
        }
        var onContentSizeDidChange: ContentSizeDidChange? = nil {
            didSet {
                self.onContentSizeDidChange?(self.contentSize)
            }
        }
        var scrollEnabled: Bool {
            get { return self.tableView.isScrollEnabled }
            set { self.tableView.isScrollEnabled = newValue }
        }
        
        // MARK: -
        
        var scrollViewDidScroll: OnScrollViewDidScroll?
        var scrollViewDidEndScrolling: OnScrollViewDidEndScrolling?
        
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
            self.setupTableView()
            self.setupRefreshControl()
            
            self.setupLayout()
            
            self.observeTableViewSizeChanges()
            
            let request = TransactionsListScene.Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                businessLogic.onViewDidLoad(request: request)
            })
        }
        
        override func observeValue(
            forKeyPath keyPath: String?,
            of object: Any?,
            change: [NSKeyValueChangeKey: Any]?,
            context: UnsafeMutableRawPointer?
            ) {
            
            guard let table = object as? UITableView,
                table == self.tableView,
                keyPath == "contentSize"
                else {
                    super.observeValue(
                        forKeyPath: keyPath,
                        of: object,
                        change: change,
                        context: context
                    )
                    return
            }
            
            self.onContentSizeDidChange?(self.contentSize)
        }
        
        func reloadTransactions() {
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                let request = TransactionsListScene.Event.DidInitiateRefresh.Request()
                businessLogic.onDidInitiateRefresh(request: request)
            })
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupEmptyLabel() { }
        
        private func setupTableView() {
            self.tableView.backgroundColor = UIColor.clear
            self.tableView.separatorColor = Theme.Colors.separatorOnContentBackgroundColor
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.tableView.register(classes: [TransactionsListTableViewCell.Model.self])
            self.tableView.rowHeight = UITableViewAutomaticDimension
            self.tableView.estimatedRowHeight = 85
            self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            self.tableView.refreshControl = self.refreshControl
        }
        
        private func setupRefreshControl() {
            self.refreshControl.addTarget(self, action: #selector(self.refreshAction), for: .valueChanged)
        }
        
        private func setupLayout() {
            self.view.addSubview(self.emptyLabel)
            self.view.addSubview(self.tableView)
            self.view.addSubview(self.stickyHeader)
            
            self.emptyLabel.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
                make.left.top.greaterThanOrEqualToSuperview().inset(15)
                make.right.bottom.lessThanOrEqualToSuperview().inset(15)
            }
            
            self.tableView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            
            self.stickyHeader.snp.makeConstraints { (make) in
                make.top.equalToSuperview().inset(6)
                make.left.right.equalToSuperview().inset(8)
                make.height.equalTo(32)
            }
        }
        
        private func observeTableViewSizeChanges() {
            self.tableView.addObserver(
                self,
                forKeyPath: "contentSize",
                options: [.new, .old],
                context: nil
            )
        }
        
        private func indexPathInBounds(_ indexPath: IndexPath) -> Bool {
            return self.sections.indexInBounds(indexPath.section)
                && self.sections[indexPath.section].rows.indexInBounds(indexPath.row)
        }
        
        private func modelForIndexPath(_ indexPath: IndexPath) -> TransactionsListTableViewCell.Model? {
            guard self.indexPathInBounds(indexPath) else {
                return nil
            }
            return self.sections[indexPath.section].rows[indexPath.row]
        }
        
        private func sectionForIndex(_ index: Int) -> Model.SectionViewModel? {
            guard self.sections.indexInBounds(index) else {
                return nil
            }
            return self.sections[index]
        }
        
        // MARK: Refresh
        
        @objc private func refreshAction() {
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                let request = Event.DidInitiateRefresh.Request()
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
            guard self.refreshControl.isRefreshing else {
                return
            }
            self.endRefreshing()
            self.hideRefreshControlIfNeeded(animated: animated)
        }
        
        private func endRefreshing() {
            self.refreshControl.endRefreshing()
        }
        
        private func revealRefreshControlIfNeeded(animated: Bool) {
            if self.tableView.contentOffset.y <= -self.tableView.contentInset.top / 2 {
                self.revealRefreshControl(animated: animated)
            }
        }
        
        private func revealRefreshControl(animated: Bool) {
            self.setOffset(withRefreshControl: true, animated: animated)
        }
        
        private func hideRefreshControlIfNeeded(animated: Bool) {
            if self.tableView.contentOffset.y <= -self.tableView.contentInset.top {
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
            oldOffset.y = -self.tableView.contentInset.top
            if withRefreshControl {
                oldOffset.y -= self.refreshControl.frame.height
            }
            self.tableView.setContentOffset(oldOffset, animated: animated)
        }
        
        private func updateSectionTitle() {
            if let currentTopIndexPath: IndexPath = self.tableView.indexPathsForVisibleRows?.first {
                self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    let request = Event.ScrollViewDidScroll.Request(indexPath: currentTopIndexPath)
                    businessLogic.onScrollViewDidScroll(request: request)
                })
            }
        }
    }
}

extension TransactionsListScene.ViewController: TransactionsListScene.DisplayLogic {
    func displayTransactionsDidUpdate(viewModel: TransactionsListScene.Event.TransactionsDidUpdate.ViewModel) {
        switch viewModel {
            
        case .empty(let title):
            self.sections = []
            self.emptyLabel.text = title
            self.emptyLabel.isHidden = false
            
        case .sections(let sections):
            self.sections = sections
            self.emptyLabel.isHidden = true
        }
        self.tableView.reloadData()
        self.updateSectionTitle()
    }
    
    func displayLoadingStatusDidChange(viewModel: TransactionsListScene.Event.LoadingStatusDidChange.ViewModel) {
        switch viewModel {
            
        case .loaded:
            self.hideRefresh(animated: true)
            
        case .loading:
            self.showRefresh(animated: true)
        }
    }
    
    func displayHeaderTitleDidChange(viewModel: TransactionsListScene.Event.HeaderTitleDidChange.ViewModel) {
        self.stickyHeader.setText(viewModel.title, animation: viewModel.animation)
    }
}

extension TransactionsListScene.ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let model = self.modelForIndexPath(indexPath) else {
            return
        }
        self.routing?.onDidSelectItemWithIdentifier(model.identifier, model.asset)
    }
}

extension TransactionsListScene.ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let model = self.modelForIndexPath(indexPath) else {
            return UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(with: model, for: indexPath)
        return cell
    }
}

extension TransactionsListScene.ViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.oldPanTranslation = 0
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.updateSectionTitle()
        
        if scrollView.contentOffset.y > -self.minimumContentInset {
            self.stickyHeader.showHeader()
        } else {
            self.stickyHeader.hideHeader()
        }
        let maxContentOffset = max(self.minimumContentInset, -scrollView.contentOffset.y)
        self.stickyHeader.setHeaderPosition(maxContentOffset + self.stickyHeader.frame.height / 2)
        
        let translation = scrollView.panGestureRecognizer.translation(in: self.view).y
        let delta = translation - self.oldPanTranslation
        self.oldPanTranslation = translation
        let currentOffset = scrollView.contentOffset.y
        let absoluteBottom: CGFloat = scrollView.contentSize.height - scrollView.frame.size.height
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        let deltaOffset = maximumOffset - currentOffset
        
        if delta < 0,
            currentOffset >= absoluteBottom,
            deltaOffset <= 0 {
            
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                let request = TransactionsListScene.Event.DidInitiateLoadMore.Request()
                businessLogic.onDidInitiateLoadMore(request: request)
            })
        }
        
        let scrolledToTop: Bool
        if self.oldContentOffset > currentOffset {
            scrolledToTop = true
        } else {
            scrolledToTop = false
        }
        self.oldContentOffset = currentOffset
        self.scrollViewDidScroll?(scrollView, scrolledToTop)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !scrollView.isDragging && !scrollView.isTracking {
            self.scrollViewDidEndScrolling?(scrollView)
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.scrollViewDidEndScrolling?(scrollView)
        }
    }
}

extension TransactionsListScene.ViewController: FlexibleHeaderContainerContentViewControllerProtocol {
    var viewController: UIViewController {
        return self
    }
    
    func setTopContentInset(_ inset: CGFloat) {
        self.tableView.contentInset.top = inset
        self.tableView.scrollIndicatorInsets.top = inset
    }
    
    func setMinimumTopContentInset(_ inset: CGFloat) {
        self.minimumContentInset = inset
    }
}
