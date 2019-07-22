import UIKit
import RxSwift
import Charts

public protocol BalancesListDisplayLogic: class {
    typealias Event = BalancesList.Event
    
    func displaySectionsUpdated(viewModel: Event.SectionsUpdated.ViewModel)
    func displayLoadingStatusDidChange(viewModel: Event.LoadingStatusDidChange.ViewModel)
    func displayPieChartEntriesChanged(viewModel: Event.PieChartEntriesChanged.ViewModel)
    func displayPieChartBalanceSelected(viewModel: Event.PieChartBalanceSelected.ViewModel)
    func displayError(viewModel: Event.Error.ViewModel)
}

extension BalancesList {
    public typealias DisplayLogic = BalancesListDisplayLogic
    
    @objc(BalancesListViewController)
    public class ViewController: UIViewController {
        
        public typealias Event = BalancesList.Event
        public typealias Model = BalancesList.Model
        
        // MARK: - Private properties
        
        private let tableView: UITableView = UITableView(frame: .zero, style: .grouped)
        private let refreshControl: UIRefreshControl = UIRefreshControl()
        
        private var sections: [Model.SectionViewModel] = [] {
            didSet {
                if self.refreshControl.isRefreshing {
                    self.refreshControl.endRefreshing()
                }
                UIView.animate(
                    withDuration: 0.5,
                    animations: {
                        self.tableView.reloadData()
                })
            }
        }
        
        private let disposeBag: DisposeBag = DisposeBag()
        
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
            
            self.setupView()
            self.setupTableView()
            self.setupRefreshControl()
            self.setupLayout()
            
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        // MARK: - Private
        
        private func updateContentOffset(offset: CGPoint) {
            if offset.y > 0 {
                self.routing?.showShadow()
            } else {
                self.routing?.hideShadow()
            }
        }
        
        private func findCell<CellViewModelType: CellViewAnyModel, CellType: UITableViewCell>(
            cellIdentifier: Model.CellIdentifier,
            cellViewModelType: CellViewModelType.Type,
            cellType: CellType.Type
            ) -> (vm: CellViewModelType, ip: IndexPath, cc: CellType?)? {
            
            for (sectionIndex, section) in self.sections.enumerated() {
                for (cellIndex, cell) in section.cells.enumerated() {
                    guard let chartCellViewModel = cell as? CellViewModelType else {
                        continue
                    }
                    
                    let indexPath = IndexPath(row: cellIndex, section: sectionIndex)
                    if let cell = self.tableView.cellForRow(at: indexPath) {
                        if let chartCell = cell as? CellType {
                            return (chartCellViewModel, indexPath, chartCell)
                        } else {
                            return nil
                        }
                    } else {
                        return (chartCellViewModel, indexPath, nil)
                    }
                }
            }
            
            return nil
        }
        
        // MARK: - Setup
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupTableView() {
            self.tableView.backgroundColor = Theme.Colors.contentBackgroundColor
            self.tableView.register(classes: [
                HeaderCell.ViewModel.self,
                BalanceCell.ViewModel.self,
                PieChartCell.ViewModel.self
                ]
            )
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.tableView.separatorStyle = .none
            self.tableView.sectionFooterHeight = 0.0
            self.tableView.estimatedRowHeight = UITableView.automaticDimension
            self.tableView.rowHeight = UITableView.automaticDimension
            
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
        
        private func setupRefreshControl() {
            self.refreshControl
                .rx
                .controlEvent(.valueChanged)
                .asDriver()
                .drive(onNext: { [weak self] (_) in
                    let request = Event.RefreshInitiated.Request()
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onRefreshInitiated(request: request)
                    })
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupLayout() {
            self.view.addSubview(self.tableView)
            self.tableView.addSubview(self.refreshControl)
            
            self.tableView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }
}

extension BalancesList.ViewController: BalancesList.DisplayLogic {
    
    public func displaySectionsUpdated(viewModel: Event.SectionsUpdated.ViewModel) {
        self.sections = viewModel.sections
    }
    
    public func displayLoadingStatusDidChange(viewModel: Event.LoadingStatusDidChange.ViewModel) {
        switch viewModel {
            
        case .loaded:
            self.routing?.hideProgress()
            
        case .loading:
            self.routing?.showProgress()
        }
    }
    
    public func displayPieChartEntriesChanged(viewModel: Event.PieChartEntriesChanged.ViewModel) {
        
    }
    
    public func displayPieChartBalanceSelected(viewModel: Event.PieChartBalanceSelected.ViewModel) {
        guard let (chartViewModel, indexPath, cell) = self.findCell(
            cellIdentifier: .chart,
            cellViewModelType: BalancesList.PieChartCell.ViewModel.self,
            cellType: BalancesList.PieChartCell.View.self
            ) else {
                return
        }
        
        guard let chartCell = cell else {
            return
        }
        var udpdatedChartViewModel = chartViewModel
        udpdatedChartViewModel.chartViewModel = viewModel.pieChartViewModel
        udpdatedChartViewModel.legendCells = viewModel.legendCells
        udpdatedChartViewModel.setup(cell: chartCell)
        self.sections[indexPath.section].cells[indexPath.row] = udpdatedChartViewModel
    }
    
    public func displayError(viewModel: Event.Error.ViewModel) {
        if self.refreshControl.isRefreshing {
            self.refreshControl.endRefreshing()
        }
        self.routing?.showError(viewModel.error)
    }
}

extension BalancesList.ViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = self.sections[indexPath.section].cells[indexPath.row]
        if let balancesModel = model as? BalancesList.BalanceCell.ViewModel {
            self.routing?.onBalanceSelected(balancesModel.balanceId)
        }
    }
}

extension BalancesList.ViewController: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].cells.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.sections[indexPath.section].cells[indexPath.row]
        let cell = tableView.dequeueReusableCell(with: model, for: indexPath)
        
        if let chartCell = cell as? BalancesList.PieChartCell.View {
            chartCell.onChartBalanceSelected = { [weak self] (value) in
                let request = Event.PieChartBalanceSelected.Request(value: value)
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onPieChartBalanceSelected(request: request)
                })
            }
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let model = self.sections[indexPath.section].cells[indexPath.row]
        
        if model as? BalancesList.HeaderCell.ViewModel != nil {
            return 30.0
        } else if model as? BalancesList.BalanceCell.ViewModel != nil {
            return 90.0
        } else if model as? BalancesList.LegendCell.ViewModel != nil {
            return 44.0
        } else if model as? BalancesList.PieChartCell.ViewModel != nil {
            return 240.0
        } else {
            return 0.0
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let model = self.sections[indexPath.section].cells[indexPath.row]
        if model as? BalancesList.HeaderCell.ViewModel != nil {
            return 30.0
        } else if model as? BalancesList.BalanceCell.ViewModel != nil {
            return 90.0
        } else if model as? BalancesList.LegendCell.ViewModel != nil {
            return 44.0
        } else if model as? BalancesList.PieChartCell.ViewModel != nil {
            return 240.0
        } else {
            return 0.0
        }
    }
}
