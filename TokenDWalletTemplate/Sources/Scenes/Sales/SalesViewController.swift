import UIKit
import RxSwift
import RxCocoa

protocol SalesDisplayLogic: class {
    func displaySectionsUpdated(viewModel: Sales.Event.SectionsUpdated.ViewModel)
    func displayLoadingStatusDidChange(viewModel: Sales.Event.LoadingStatusDidChange.ViewModel)
    func displayEmptyResult(viewModel: Sales.Event.EmptyResult.ViewModel)
}

protocol SalesSceneProtocol {
    typealias ContentSize = CGSize
    typealias ContentSizeDidChange = (ContentSize) -> Void
    
    var onContentSizeDidChange: ContentSizeDidChange? { get set }
    var contentSize: ContentSize { get }
}

extension Sales {
    typealias DisplayLogic = SalesDisplayLogic
    
    class ViewController: UIViewController, SalesSceneProtocol {
        
        // MARK: - Private properties
        
        private let tableView: UITableView = UITableView(frame: .zero, style: .grouped)
        private let emptyView: UILabel = SharedViewsBuilder.createEmptyLabel()
        private var sections: [Model.SectionViewModel] = []
        private var oldPanTranslation: CGFloat = 0
        private var oldContentOffset: CGFloat = 0
        private var minimumContentInset: CGFloat = 0
        
        private let loadMoreIndicator = PublishRelay<Void>()
        private let queue: DispatchQueue = DispatchQueue(
            label: NSStringFromClass(ViewController.self).queueLabel,
            qos: .userInteractive
        )
        
        var contentSize: ContentSize {
            return self.tableView.contentSize
        }
        var onContentSizeDidChange: ContentSizeDidChange? = nil {
            didSet {
                self.onContentSizeDidChange?(self.contentSize)
            }
        }
        
        private let refreshControl = UIRefreshControl()
        private let disposeBag = DisposeBag()
        
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
            self.setupRefreshControl()
            self.setupTableView()
            self.setupNavigationBar()
            self.setupLayout()
            
            self.observeTableViewSizeChanges()
            self.observeLoadMoreIndicator()
            
            let request = Sales.Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
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
        
        // MARK: - Private
        
        private func updateContentOffset(offset: CGPoint) {
            if offset.y > 0 {
                self.routing?.onShowShadow()
            } else {
                self.routing?.onHideShadow()
            }
        }
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.containerBackgroundColor
        }
        
        private func setupRefreshControl() {
            self.refreshControl
                .rx
                .controlEvent(.valueChanged)
                .asDriver()
                .drive(onNext: { [weak self] in
                    self?.refreshControl.endRefreshing()
                    let request = Event.DidInitiateRefresh.Request()
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onDidInitiateRefresh(request: request)
                    })
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupNavigationBar() {
            var items: [UIBarButtonItem] = []
            
            let pendingBarButtonItem = UIBarButtonItem(
                image: Assets.pendingIcon.image,
                style: .plain,
                target: self,
                action: nil
            )
            
            pendingBarButtonItem
                .rx
                .tap
                .asDriver()
                .drive(onNext: { [weak self] in
                    self?.routing?.onShowInvestments()
                })
                .disposed(by: self.disposeBag)
            
            items.append(pendingBarButtonItem)
            
            self.navigationItem.rightBarButtonItems = items
        }
        
        private func setupTableView() {
            let cellClasses: [CellViewAnyModel.Type] = [
                Sales.SaleListCell.ViewModel.self
            ]
            self.tableView.register(classes: cellClasses)
            self.tableView.dataSource = self
            self.tableView.delegate = self
            self.tableView.separatorColor = UIColor.clear
            self.tableView.rowHeight = UITableView.automaticDimension
            self.tableView.estimatedRowHeight = 380.0
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
        
        private func setupLayout() {
            self.view.addSubview(self.tableView)
            self.view.addSubview(self.emptyView)
            
            self.tableView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            self.emptyView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
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
        
        private func observeLoadMoreIndicator() {
            let scheduler = SerialDispatchQueueScheduler(
                queue: self.queue,
                internalSerialQueueName: self.queue.label
            )
            self.loadMoreIndicator
                .debounce(0.1, scheduler: scheduler)
                .subscribe { [weak self] (_) in
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        let request = Sales.Event.DidInitiateLoadMore.Request()
                        businessLogic.onDidInitiateLoadMore(request: request)
                    })
                }
                .disposed(by: self.disposeBag)
        }
    }
}

// MARK: - DisplayLogic

extension Sales.ViewController: Sales.DisplayLogic {
    
    func displaySectionsUpdated(viewModel: Sales.Event.SectionsUpdated.ViewModel) {
        self.sections = viewModel.sections
        self.emptyView.isHidden = true
        self.tableView.reloadData()
    }
    
    func displayLoadingStatusDidChange(viewModel: Sales.Event.LoadingStatusDidChange.ViewModel) {
        switch viewModel {
            
        case .loaded:
            self.emptyView.alpha = 1.0
            self.routing?.onHideLoading()
            
        case .loading:
            self.emptyView.alpha = 0.0
            self.routing?.onShowLoading()
        }
    }
    
    func displayEmptyResult(viewModel: Sales.Event.EmptyResult.ViewModel) {
        self.emptyView.text = viewModel.message
        self.emptyView.isHidden = false
    }
}

// MARK: - UITableViewDataSource

extension Sales.ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.sections[indexPath.section].cells[indexPath.row]
        let cell = tableView.dequeueReusableCell(with: model, for: indexPath)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension Sales.ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = self.sections[indexPath.section].cells[indexPath.row]
        guard let saleModel = model as? Sales.SaleListCell.ViewModel else {
            return
        }
        
        self.routing?.onDidSelectSale(saleModel.saleIdentifier, saleModel.asset)
    }
}

extension Sales.ViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.oldPanTranslation = 0
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
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
            
            self.loadMoreIndicator.accept(())
        }
        
        self.oldContentOffset = currentOffset
    }
}
