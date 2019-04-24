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
    public var onContentSizeChanged: ContentSizeDidChange?
    
    public var onPullToRefresh: (() -> Void)?
    public var onScrolledToBottom: (() -> Void)? {
        get { return self.delegateDatasource.onScrolledToBottom }
        set { self.delegateDatasource.onScrolledToBottom = newValue }
    }
    
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
        fatalError("init(coder:) has not been implemented")
    }
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
        ) {
        
        guard let tableObject = object as? UITableView,
            tableObject == self.tableView
            else {
                super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
                return
        }
        
        if let newSize = change?[.newKey] as? CGSize {
            self.onContentSizeChanged?(newSize)
        }
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
        self.tableView.separatorColor = Theme.Colors.separatorOnMainColor
        self.tableView.separatorInset = .zero
        self.tableView.estimatedRowHeight = 44
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        
        self.tableView.addObserver(
            self,
            forKeyPath: "contentSize",
            options: [.new],
            context: nil)
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
    
    private func setupEmptyLabel() { }
    
    private func setupLayout() {
        self.addSubview(self.tableView)
        self.tableView.addSubview(self.refreshControl)
        self.addSubview(self.emptyLabel)
        
        self.tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.emptyLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.top.leading.greaterThanOrEqualToSuperview().inset(8)
            make.trailing.bottom.lessThanOrEqualToSuperview().inset(8)
        }
    }
    
    // MARK: - Public
    
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
        
        public var cells: [OrderBookTableViewCellModel<CellType>] = []
        public var onScrolledToBottom: (() -> Void)?
        
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
        
        func tableView(
            _ tableView: UITableView,
            willDisplay cell: UITableViewCell,
            forRowAt indexPath: IndexPath
            ) {
            
            if indexPath.row == self.cells.count - 1 {
                self.onScrolledToBottom?()
            }
        }
    }
}
