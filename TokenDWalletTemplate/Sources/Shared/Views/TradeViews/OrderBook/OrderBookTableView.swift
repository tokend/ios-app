import UIKit
import RxCocoa
import RxSwift

class OrderBookTableView<CellType: OrderBookTableViewCell>: UIView {
    
    typealias ContentSizeDidChange = (_ newSize: CGSize) -> Void
    
    // MARK: - Public properties
    
    public var cells: [OrderBookTableViewCellModel<CellType>] = [] {
        didSet {
            self.delegateDatasource.cells = cells
            self.tableView.register(classes: self.cells.map({ (cellModel) -> CellViewAnyModel.Type in
                return type(of: cellModel)
            }))
            self.tableView.reloadData()
        }
    }
    
    public var onPullToRefresh: (() -> Void)?
    
    // MARK: - Private properties
    
    private let tableView: UITableView = UITableView()
    private let refreshControl: UIRefreshControl = UIRefreshControl()
    private let emptyLabel: UILabel = SharedViewsBuilder.createEmptyLabel()
    private lazy var delegateDatasource: DelegateDatasource = DelegateDatasource()
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Overridden methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.commonInit()
    }
    
    // MARK: - Private
    
    private func commonInit() {
        self.setupTableView()
        self.setupRefreshControl()
        self.setupEmptyLabel()
        
        self.setupLayout()
    }
    
    private func setupTableView() {
        self.tableView.dataSource = self.delegateDatasource
        self.tableView.delegate = self.delegateDatasource
        self.tableView.rowHeight = 44
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        self.tableView.separatorStyle = .none
    }
    
    private func setupRefreshControl() {
        self.refreshControl.rx
            .controlEvent(.valueChanged)
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.onPullToRefresh?()
            })
            .disposed(by: self.disposeBag)
    }
    
    private func setupEmptyLabel() {
        self.emptyLabel.textColor = Theme.Colors.sideTextOnContainerBackgroundColor
        self.emptyLabel.font = Theme.Fonts.smallTextFont
        self.emptyLabel.textAlignment = .center
        self.emptyLabel.numberOfLines = 0
    }
    
    private func setupLayout() {
        self.addSubview(self.tableView)
        self.tableView.addSubview(self.refreshControl)
        self.addSubview(self.emptyLabel)
        
        self.tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        self.emptyLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(8)
        }
    }
    
    // MARK: - Public
    
    public func showDataLoading(_ show: Bool) {
        if show {
            self.emptyLabel.alpha = 0.0
            if self.cells.isEmpty {
                self.showLoading()
            } else {
                self.refreshControl.beginRefreshing()
            }
        } else {
            self.emptyLabel.alpha = 1.0
            self.hideLoading()
            self.refreshControl.endRefreshing()
        }
    }
    
    public func showEmptyStateWithText(_ text: String) {
        self.emptyLabel.text = text
        self.emptyLabel.isHidden = false
    }
    
    public func hideEmptyState() {
        self.emptyLabel.isHidden = true
    }
}

extension OrderBookTableView {
    fileprivate class DelegateDatasource: NSObject, UITableViewDataSource, UITableViewDelegate {
        
        // MARK: - Public properties
        
        public var cells: [OrderBookTableViewCellModel<CellType>] = [] {
            didSet {
                self.everScrolled = false
            }
        }
        public var onScrolledToBottom: (() -> Void)?
        
        // MARK: - Private properties
        
        private var everScrolled: Bool = false
        
        // MARK: -
        
        func numberOfSections(in tableView: UITableView) -> Int {
            return 1
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return self.cells.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            return tableView.dequeueReusableCell(with: self.cells[indexPath.row], for: indexPath)
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            if let cell = tableView.cellForRow(at: indexPath) as? CellType {
                self.cells[indexPath.row].onClick?(cell)
            }
        }
        
        public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            self.everScrolled = true
        }
        
        func tableView(
            _ tableView: UITableView,
            willDisplay cell: UITableViewCell,
            forRowAt indexPath: IndexPath
            ) {
            
            if indexPath.row == self.cells.count - 1, self.everScrolled {
                self.onScrolledToBottom?()
            }
        }
    }
}
