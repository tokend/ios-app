import UIKit
import Charts

protocol SaleDetailsDisplayLogic: class {
    typealias Event = SaleDetails.Event
    
    func displaySectionsUpdated(viewModel: Event.SectionsUpdated.ViewModel)
    func displaySelectBalance(viewModel: Event.SelectBalance.ViewModel)
    func displayBalanceSelected(viewModel: Event.BalanceSelected.ViewModel)
    func displayInvestAction(viewModel: Event.InvestAction.ViewModel)
    func displayCancelInvestAction(viewModel: Event.CancelInvestAction.ViewModel)
    func displayDidSelectMoreInfoButton(viewModel: Event.DidSelectMoreInfoButton.ViewModel)
    func displaySelectChartPeriod(viewModel: Event.SelectChartPeriod.ViewModel)
    func displaySelectChartEntry(viewModel: Event.SelectChartEntry.ViewModel)
}

extension SaleDetails {
    typealias DisplayLogic = SaleDetailsDisplayLogic
    
    class ViewController: UIViewController {
        
        typealias Event = SaleDetails.Event
        
        // MARK: - Private properties
        
        private let tableView: UITableView = UITableView(frame: .zero, style: .grouped)
        private var sections: [Model.SectionViewModel] = []
        
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
            self.setupTableView()
            self.setupLayout()
            
            self.addKeyboardObserver()
            
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.containerBackgroundColor
        }
        
        private func setupTableView() {
            let cellClasses: [CellViewAnyModel.Type] = [
                DescriptionCell.ViewModel.self,
                InvestingCell.ViewModel.self,
                ChartCell.ViewModel.self
            ]
            self.tableView.register(classes: cellClasses)
            self.tableView.dataSource = self
            self.tableView.delegate = self
        }
        
        private func setupLayout() {
            self.view.addSubview(self.tableView)
            self.tableView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
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
            
            let keyboardHeight: CGFloat = attributes?.heightInContainerView(self.view, view: self.tableView) ?? 0
            var bottomInset: CGFloat = keyboardHeight
            if attributes?.showingIn(view: self.view) != true {
                if #available(iOS 11, *) {
                    bottomInset += self.view.safeAreaInsets.bottom
                } else {
                    bottomInset += self.bottomLayoutGuide.length
                }
            }
            self.tableView.contentInset.bottom = bottomInset
        }
        
        private func updateCell(_ cell: CellViewAnyModel, indexPath: IndexPath) {
            self.sections[indexPath.section].cells[indexPath.row] = cell
        }
        
        private func updateSelectChartPeriod(viewModel: Event.SelectChartPeriod.ViewModel) {
            guard let chartCell = self.findCell(
                cellIdentifier: viewModel.updatedCell.identifier,
                cellViewModelType: ChartCell.ViewModel.self,
                cellType: ChartCell.View.self
                ) else {
                    return
            }
            
            self.updateCell(viewModel.updatedCell, indexPath: chartCell.ip)
            
            if let cell = chartCell.cc {
                viewModel.viewModel.setup(cell: cell)
            }
        }
        
        private func updateInvestingCell(_ viewModel: InvestingCell.ViewModel) {
            guard let investingCell = self.findCell(
                cellIdentifier: viewModel.identifier,
                cellViewModelType: InvestingCell.ViewModel.self,
                cellType: InvestingCell.View.self
                ) else {
                    return
            }
            
            self.updateCell(viewModel, indexPath: investingCell.ip)
            
            if let cell = investingCell.cc {
                viewModel.setup(cell: cell)
            }
        }
        
        private func findCell<CellViewModelType: CellViewAnyModel, CellType: UITableViewCell>(
            cellIdentifier: CellIdentifier,
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
    }
}

// MARK: - DisplayLogic

extension SaleDetails.ViewController: SaleDetails.DisplayLogic {
    func displaySectionsUpdated(viewModel: Event.SectionsUpdated.ViewModel) {
        self.sections = viewModel.sections
        self.tableView.reloadData()
    }
    
    func displaySelectBalance(viewModel: Event.SelectBalance.ViewModel) {
        let options: [String] = viewModel.balances.map({ $0.asset })
        self.routing?.onPresentPicker(Localized(.select_asset), options, { [weak self] (selectedIndex) in
            let balance = viewModel.balances[selectedIndex]
            let request = Event.BalanceSelected.Request(balanceId: balance.balanceId)
            self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                businessLogic.onBalanceSelected(request: request)
            })
        })
    }
    
    func displayBalanceSelected(viewModel: Event.BalanceSelected.ViewModel) {
        self.updateInvestingCell(viewModel.updatedCell)
    }
    
    func displayInvestAction(viewModel: Event.InvestAction.ViewModel) {
        switch viewModel {
            
        case .loading:
            self.routing?.onShowProgress()
            
        case .loaded:
            self.routing?.onHideProgress()
            
        case .failed(let message):
            self.routing?.onShowError(message)
            
        case .succeeded(let saleInvestModel):
            self.routing?.onSaleInvestAction(saleInvestModel)
        }
    }
    
    func displayCancelInvestAction(viewModel: Event.CancelInvestAction.ViewModel) {
        switch viewModel {
            
        case .loading:
            self.routing?.onShowProgress()
            
        case .loaded:
            self.routing?.onHideProgress()
            
        case .failed(let message):
            self.routing?.onShowError(message)
        }
    }
    
    func displayDidSelectMoreInfoButton(viewModel: SaleDetails.Event.DidSelectMoreInfoButton.ViewModel) {
        let saleInfoModel = SaleDetails.Model.SaleInfoModel(
            saleId: viewModel.saleId,
            blobId: viewModel.blobId,
            asset: viewModel.asset
        )
        self.routing?.onSaleInfoAction(saleInfoModel)
    }
    
    func displaySelectChartPeriod(viewModel: Event.SelectChartPeriod.ViewModel) {
        self.updateSelectChartPeriod(viewModel: viewModel)
    }
    
    func displaySelectChartEntry(viewModel: Event.SelectChartEntry.ViewModel) {
        guard let chartCell = self.findCell(
            cellIdentifier: viewModel.viewModel.identifier,
            cellViewModelType: SaleDetails.ChartCell.ViewModel.self,
            cellType: SaleDetails.ChartCell.View.self
            ) else {
                return
        }
        
        if let cell = chartCell.cc {
            viewModel.viewModel.setup(cell: cell)
        }
    }
}

// MARK: - UITableViewDelegate

extension SaleDetails.ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let model = self.sections[indexPath.section].cells[indexPath.row]
        let cell = tableView.dequeueReusableCell(with: model, for: indexPath)
        
        let estimatedHeight: CGFloat
        
        if cell is SaleDetails.InvestingCell.View {
            estimatedHeight = 200.0
        } else if cell is SaleDetails.DescriptionCell.View {
            estimatedHeight = 260.0
        } else if cell is SaleDetails.ChartCell.View {
            estimatedHeight = 300.0
        } else {
            estimatedHeight = tableView.estimatedRowHeight
        }
        
        return estimatedHeight
    }
}

// MARK: - UITableViewDataSource

extension SaleDetails.ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.sections[indexPath.section].cells[indexPath.row]
        let cell = tableView.dequeueReusableCell(with: model, for: indexPath)
        
        if let cell = cell as? SaleDetails.InvestingCell.View {
            cell.onSelectBalance = { [weak self] (identifier) in
                let request = Event.SelectBalance.Request()
                self?.interactorDispatch?.sendRequest { businessLogic in
                    businessLogic.onSelectBalance(request: request)
                }
            }
            cell.onInvestAction = { [weak self] (identifier) in
                let request = Event.InvestAction.Request()
                self?.interactorDispatch?.sendRequest { businessLogic in
                    businessLogic.onInvestAction(request: request)
                }
            }
            cell.onCancelInvestAction = { [weak self] (identifier) in
                let onSelected: ((Int) -> Void) = { _ in
                    let request = Event.CancelInvestAction.Request()
                    self?.interactorDispatch?.sendRequest { businessLogic in
                        businessLogic.onCancelInvestAction(request: request)
                    }
                }
                self?.routing?.onSaleCancelInvestAction(
                    Localized(.cancel_investment),
                    Localized(.are_you_sure_you_want_to_cancel_investment),
                    [Localized(.yes)],
                    onSelected
                )
            }
            cell.onDidEnterAmount = { [weak self] (amount) in
                let request = Event.EditAmount.Request(amount: amount)
                self?.interactorDispatch?.sendRequest { businessLogic in
                    businessLogic.onEditAmount(request: request)
                }
            }
        } else if let cell = cell as? SaleDetails.DescriptionCell.View {
            cell.onDidSelectMoreInfoButton = { [weak self] (identifier) in
                let request = Event.DidSelectMoreInfoButton.Request()
                self?.interactorDispatch?.sendRequest { businessLogic in
                    businessLogic.onDidSelectMoreInfoButton(request: request)
                }
            }
        } else if let cell = cell as? SaleDetails.ChartCell.View {
            cell.didSelectPickerItem = { [weak self] (period) in
                let request = Event.SelectChartPeriod.Request(period: period)
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onSelectChartPeriod(request: request)
                })
            }
            
            cell.didSelectChartItem = { [weak self] (charItemIndex) in
                let request = Event.SelectChartEntry.Request(chartEntryIndex: charItemIndex)
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onSelectChartEntry(request: request)
                })
            }
        }
        
        return cell
    }
}
