import UIKit
import RxSwift
import ActionsList

// MARK: - TransactionsListSceneDisplayLogic

protocol TransactionsListSceneDisplayLogic: class {
    
    typealias Event = TransactionsListScene.Event
    
    func displayTransactionsDidUpdate(viewModel: Event.TransactionsDidUpdate.ViewModel)
    func displayActionsDidChange(viewModel: Event.ActionsDidChange.ViewModel)
    func displayLoadingStatusDidChange(viewModel: Event.LoadingStatusDidChange.ViewModel)
    func displayHeaderTitleDidChange(viewModel: Event.HeaderTitleDidChange.ViewModel)
    func displaySendAction(viewModel: Event.SendAction.ViewModel)
}

// MARK: - TransactionsListSceneProtocol

protocol TransactionsListSceneProtocol {
    typealias ContentSize = CGSize
    typealias ContentSizeDidChange = (ContentSize) -> Void
    
    var asset: String { get set }
    var onContentSizeDidChange: ContentSizeDidChange? { get set }
    var contentSize: ContentSize { get }
}

// MARK: - TransactionsListScene.ViewController

extension TransactionsListScene {
    typealias DisplayLogic = TransactionsListSceneDisplayLogic
    
    class ViewController: UIViewController, TransactionsListSceneProtocol {
        
        typealias Event = TransactionsListScene.Event
        
        // MARK: - Private properties
        
        private let emptyLabel: UILabel = SharedViewsBuilder.createEmptyLabel()
        private let tableView: UITableView = UITableView(frame: .zero, style: .plain)
        private let stickyHeader: TableViewStickyHeader = TableViewStickyHeader()
        private let floatyActionButton: UIButton = UIButton()
        private let refreshControl: UIRefreshControl = UIRefreshControl()
        private var sections: [Model.SectionViewModel] = []
        private var oldPanTranslation: CGFloat = 0.0
        private var oldContentOffset: CGFloat = 0.0
        private var minimumContentInset: CGFloat = 0.0
        private var topContentInset: CGFloat = 0.0 {
            didSet {
                self.tableView.contentInset.top = self.topContentInset
                self.tableView.scrollIndicatorInsets.top = self.topContentInset
            }
        }
        private let iconSize: CGFloat = 60.0
        private let disposeBag = DisposeBag()
        private var actions: [ActionsListDefaultButtonModel] = []
        private var actionsList: ActionsListModel?
        
        // MARK: -
        
        // TODO: - Remove asset and balance id properties
        
        var asset: String = "" {
            didSet {
                self.interactorDispatch?.sendRequest(requestBlock: { [weak self] (businessLogic) in
                    guard let asset = self?.asset else { return }
                    let request = Event.AssetDidChange.Request(asset: asset)
                    businessLogic.onAssetDidChange(request: request)
                })
            }
        }
        var balanceId: String? {
            didSet {
                self.interactorDispatch?.sendRequest(requestBlock: { [weak self] (businessLogic) in
                    let request = Event.BalanceDidChange.Request(balanceId: self?.balanceId)
                    businessLogic.onBalanceDidChange(request: request)
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
        private var viewConfig: Model.ViewConfig?
        
        func inject(
            interactorDispatch: InteractorDispatch?,
            viewConfig: Model.ViewConfig?,
            routing: Routing?
            ) {
            
            self.interactorDispatch = interactorDispatch
            self.viewConfig = viewConfig
            self.routing = routing
        }
        
        // MARK: - Overridden
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.setupView()
            self.setupEmptyLabel()
            self.setupTableView()
            self.setupFloatActionButton()
            self.setupRefreshControl()
            
            self.setupLayout()
            
            self.observeTableViewSizeChanges()
            
            let request = Event.ViewDidLoad.Request()
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
                let request = Event.DidInitiateRefresh.Request()
                businessLogic.onDidInitiateRefresh(request: request)
            })
        }
        
        // MARK: - Private
        
        private func showActions() {
            self.actionsList = self.floatyActionButton.createActionsList()
            
            self.actions.forEach { (action) in
                self.actionsList?.add(action: action)
            }
            self.actionsList?.present()
        }
        
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
            self.tableView.rowHeight = UITableView.automaticDimension
            self.tableView.estimatedRowHeight = 85
            self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            self.tableView.refreshControl = self.refreshControl
            self.tableView
                .rx
                .contentOffset
                .asDriver()
                .throttle(0.25)
                .drive(onNext: { [weak self] (offset) in
                    self?.updateContentOffset(offset: offset)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupFloatActionButton() {
            if let isHidden = self.viewConfig?.actionButtonIsHidden {
                self.floatyActionButton.isHidden = isHidden
            }
            
            self.floatyActionButton.backgroundColor = Theme.Colors.accentColor
            self.floatyActionButton.setImage(
                Assets.walletIcon.image,
                for: .normal
            )
            self.floatyActionButton.tintColor = Theme.Colors.textOnAccentColor
            self.floatyActionButton.layer.cornerRadius = self.iconSize / 2
            self.floatyActionButton
                .rx
                .tap
                .asDriver()
                .drive(onNext: { [weak self] (_) in
                    self?.showActions()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupRefreshControl() {
            self.refreshControl.addTarget(self, action: #selector(self.refreshAction), for: .valueChanged)
        }
        
        private func setupLayout() {
            self.view.addSubview(self.emptyLabel)
            self.view.addSubview(self.tableView)
            self.view.addSubview(self.stickyHeader)
            self.view.addSubview(self.floatyActionButton)
            
            self.emptyLabel.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
                make.leading.top.greaterThanOrEqualToSuperview().inset(15)
                make.trailing.bottom.lessThanOrEqualToSuperview().inset(15)
            }
            
            self.tableView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            
            self.floatyActionButton.snp.makeConstraints { (make) in
                make.trailing.equalToSuperview().inset(15.0)
                make.bottom.equalTo(self.view.safeArea.bottom).inset(15.0)
                make.height.width.equalTo(self.iconSize)
            }
            
            self.stickyHeader.snp.makeConstraints { (make) in
                make.top.equalToSuperview().inset(6)
                make.leading.trailing.equalToSuperview().inset(8)
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
        
        private func updateContentOffset(offset: CGPoint) {
            if offset.y > 0 {
                self.routing?.showShadow()
            } else {
                self.routing?.hideShadow()
            }
        }
        
        private func updateSectionTitle() {
            if let currentTopIndexPath: IndexPath = self.tableView.indexPathsForVisibleRows?.first {
                self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    let request = Event.ScrollViewDidScroll.Request(indexPath: currentTopIndexPath)
                    businessLogic.onScrollViewDidScroll(request: request)
                })
            }
        }
        
        // MARK: Refresh
        
        @objc private func refreshAction() {
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                let request = Event.DidInitiateRefresh.Request()
                businessLogic.onDidInitiateRefresh(request: request)
            })
        }
        
        private func showRefresh(animated: Bool) {
            guard !self.refreshControl.isRefreshing else {
                return
            }
            self.beginRefreshing()
            self.revealRefreshControlIfNeeded(animated: animated)
        }
        
        private func beginRefreshing() {
            self.refreshControl.beginRefreshing()
        }
        
        private func hideRefresh(animated: Bool) {
            guard self.refreshControl.isRefreshing else {
                return
            }
            self.hideRefreshControlIfNeeded(animated: animated)
            self.endRefreshing()
        }
        
        private func endRefreshing() {
            self.refreshControl.endRefreshing()
        }
        
        private func revealRefreshControlIfNeeded(animated: Bool) {
            let targetOffset = self.getZeroTableOffset(withRefreshControl: true)
            if self.tableView.contentOffset.y > targetOffset {
                self.setOffset(withRefreshControl: true, animated: animated)
            }
        }
        
        private func hideRefreshControlIfNeeded(animated: Bool) {
            let targetOffset = self.getZeroTableOffset(withRefreshControl: false)
            if self.tableView.contentOffset.y < targetOffset {
                self.setOffset(withRefreshControl: false, animated: animated)
            }
        }
        
        private func setOffset(withRefreshControl: Bool, animated: Bool) {
            guard !self.tableView.isDecelerating,
                !self.tableView.isTracking,
                !self.tableView.isDragging
                else {
                    return
            }
            
            let targetOffset = self.getZeroTableOffset(withRefreshControl: withRefreshControl)
            var contentOffset = self.tableView.contentOffset
            contentOffset.y = targetOffset
            self.tableView.setContentOffset(contentOffset, animated: animated)
        }
        
        private func getZeroTableOffset(withRefreshControl: Bool) -> CGFloat {
            var offset = -self.topContentInset
            if withRefreshControl {
                offset -= self.refreshControl.frame.height
            }
            
            return offset
        }
        
        private func getRefreshHeight() -> CGFloat {
            return self.refreshControl.frame.height
        }
    }
}

// MARK: - TransactionsListScene.DisplayLogic

extension TransactionsListScene.ViewController: TransactionsListScene.DisplayLogic {
    
    func displayTransactionsDidUpdate(viewModel: Event.TransactionsDidUpdate.ViewModel) {
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
    
    func displayActionsDidChange(viewModel: Event.ActionsDidChange.ViewModel) {
        if let viewConfig = self.viewConfig,
            viewConfig.actionButtonIsHidden {
            return
        } else if viewModel.actions.isEmpty {
            self.floatyActionButton.isHidden = true
            return
        } else {
            self.floatyActionButton.isHidden = false
        }
        
        let actions = viewModel.actions.map { [weak self] (item) -> ActionsListDefaultButtonModel in
            
            let action: (ActionsListDefaultButtonModel) -> Void = { (model) in
                self?.actionsList?.dismiss({
                    switch item.type {
                        
                    case .deposit(let assetId):
                        self?.routing?.showDeposit(assetId)
                        
                    case .receive:
                        self?.routing?.showReceive()
                        
                    case .send(let balanceId):
                        self?.routing?.showSendPayment(balanceId)
                        
                    case .withdraw(let balanceId):
                        self?.routing?.showWithdraw(balanceId)
                    }
                })
            }
            let actionModel = ActionsListDefaultButtonModel(
                localizedTitle: item.title,
                image: item.image,
                action: action,
                isEnabled: true
            )
            actionModel.appearance.backgroundColor = Theme.Colors.clear
            actionModel.appearance.tint = Theme.Colors.accentColor
            return actionModel
        }
        
        self.actions = actions
    }
    
    func displayLoadingStatusDidChange(viewModel: Event.LoadingStatusDidChange.ViewModel) {
        switch viewModel {
            
        case .loaded:
            self.hideRefresh(animated: true)
            
        case .loading:
            self.showRefresh(animated: true)
        }
    }
    
    func displayHeaderTitleDidChange(viewModel: Event.HeaderTitleDidChange.ViewModel) {
        self.stickyHeader.setText(viewModel.title, animation: viewModel.animation)
    }
    
    func displaySendAction(viewModel: Event.SendAction.ViewModel) {
        self.routing?.showSendPayment(viewModel.balanceId)
    }
}

// MARK: - UITableViewDelegate

extension TransactionsListScene.ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let model = self.modelForIndexPath(indexPath) else {
            return
        }
        self.routing?.onDidSelectItemWithIdentifier(model.identifier, model.balanceId)
    }
}

// MARK: - UITableViewDataSource

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

// MARK: - UIScrollViewDelegate

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
                let request = Event.DidInitiateLoadMore.Request()
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

// MARK: - FlexibleHeaderContainerContentViewControllerProtocol

extension TransactionsListScene.ViewController: FlexibleHeaderContainerContentViewControllerProtocol {
    
    var viewController: UIViewController {
        return self
    }
    
    func setTopContentInset(_ inset: CGFloat) {
        self.topContentInset = inset
    }
    
    func setMinimumTopContentInset(_ inset: CGFloat) {
        self.minimumContentInset = inset
    }
}
