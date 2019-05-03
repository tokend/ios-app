import UIKit
import RxCocoa
import RxSwift

public protocol LimitsDisplayLogic: class {
    
    typealias Event = Limits.Event
    
    func displayLoadingStatus(viewModel: Event.LoadingStatus.ViewModel)
    func displayError(viewModel: Event.Error.ViewModel)
    func displayLimitsUpdated(viewModel: Event.LimitsUpdated.ViewModel)
}

extension Limits {
    
    public typealias DisplayLogic = LimitsDisplayLogic
    
    @objc(LimitsViewController)
    public class ViewController: UIViewController {
        
        public typealias Event = Limits.Event
        public typealias Model = Limits.Model
        
        // MARK: - Private properties
        
        private let picker: HorizontalPicker = HorizontalPicker(frame: CGRect.zero)
        private let tableView: DynamicTableView = DynamicTableView()
        
        private var items: [Model.LimitViewModel] = [] {
            didSet {
                self.tableView.reloadData()
            }
        }
        
        private let disposeBag = DisposeBag()
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
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
            
            self.setupPicker()
            self.setupTableView()
            self.setupRefreshControl()
            self.setupLayout()
            
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        private func setupPicker() {
            self.picker.backgroundColor = Theme.Colors.mainColor
            self.picker.tintColor = Theme.Colors.textOnMainColor
        }
        
        private func setupTableView() {
            self.tableView.backgroundColor = Theme.Colors.containerBackgroundColor
            self.tableView.dataSource = self
        }
        
        private func setupRefreshControl() {
            self.tableView.pullToRefreshEnabled = true
            self.tableView.onPullToRefresh = { [weak self] in
                let request = Event.PullToRefresh.Request()
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onPullToRefresh(request: request)
                })
            }
        }
        
        private func setupLayout() {
            self.view.addSubview(self.picker)
            self.view.addSubview(self.tableView)
            
            self.picker.snp.makeConstraints { (make) in
                make.leading.trailing.top.equalToSuperview()
            }
            
            self.tableView.snp.makeConstraints { (make) in
                make.top.equalTo(self.picker.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
        }
    }
}

// MARK: - DynamicTableViewDataSourceDelegate

extension Limits.ViewController: DynamicTableViewDataSourceDelegate {
    
    public func numberOfSections() -> Int {
        return 1
    }
    
    public func numberOfRowsIn(section: Int) -> Int {
        return self.items.count
    }
    
    public func contentAt(indexPath: IndexPath, currentContent: UIView?) -> UIView? {
        let view: Limits.ListView
        if let prevView = currentContent as? Limits.ListView {
            view = prevView
        } else {
            view = Limits.ListView()
        }
        
        let item = self.items[indexPath.row]
        
        
        
        return view
    }
    
    public func onSelectRowAt(indexPath: IndexPath) {
        
    }
    
    public func showsCellSeparator() -> Bool {
        return true
    }
}

extension Limits.ViewController: Limits.DisplayLogic {
    
    public func displayLoadingStatus(viewModel: Event.LoadingStatus.ViewModel) {
        if viewModel.isLoading {
            self.tableView.beginRefreshing()
        } else {
            self.tableView.endRefreshing()
        }
    }
    
    public func displayError(viewModel: Event.Error.ViewModel) {
        self.routing?.onShowError(viewModel.error)
    }
    
    public func displayLimitsUpdated(viewModel: Event.LimitsUpdated.ViewModel) {
        
    }
}
