import UIKit
import RxSwift
import Charts

public protocol BalancesListDisplayLogic: class {
    typealias Event = BalancesList.Event
    
    func displaySectionsUpdated(viewModel: Event.SectionsUpdated.ViewModel)
    func displayLoadingStatusDidChange(viewModel: Event.LoadingStatusDidChange.ViewModel)
    func displayPieChartEntriesChanged(viewModel: Event.PieChartEntriesChanged.ViewModel)
    func displayPieChartBalanceSelected(viewModel: Event.PieChartBalanceSelected.ViewModel)
}

extension BalancesList {
    public typealias DisplayLogic = BalancesListDisplayLogic
    
    @objc(BalancesListViewController)
    public class ViewController: UIViewController {
        
        public typealias Event = BalancesList.Event
        public typealias Model = BalancesList.Model
        
        // MARK: - Private properties
        
        private let tableView: UITableView = UITableView(frame: .zero, style: .grouped)
        
        private var sections: [Model.SectionViewModel] = []
        
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
            
            self.tableView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }
}

extension BalancesList.ViewController: BalancesList.DisplayLogic {
    
    public func displaySectionsUpdated(viewModel: Event.SectionsUpdated.ViewModel) {
        self.sections = viewModel.sections
        self.tableView.reloadData()
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
}
