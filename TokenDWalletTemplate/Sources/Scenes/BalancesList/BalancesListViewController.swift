import UIKit

public protocol BalancesListDisplayLogic: class {
    typealias Event = BalancesList.Event
    
    func displayCellsWasUpdated(viewModel: Event.CellsWasUpdated.ViewModel)
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
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupTableView() {
            self.tableView.backgroundColor = Theme.Colors.contentBackgroundColor
            self.tableView.register(classes: [
                    HeaderCell.ViewModel.self,
                    BalanceCell.ViewModel.self
                ]
            )
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.tableView.separatorStyle = .none
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
    
    public func displayCellsWasUpdated(viewModel: Event.CellsWasUpdated.ViewModel) {
        self.sections = viewModel.sections
        self.tableView.reloadData()
    }
}

extension BalancesList.ViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = self.sections[indexPath.section].cells[indexPath.row]
        switch model {
            
        case .header:
            return
            
        case .balance(let model):
            self.routing?.onBalanceSelected(model.balanceId)
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
        switch model {
            
        case .balance(let balance):
            return tableView.dequeueReusableCell(with: balance, for: indexPath)
            
        case .header(let header):
            return tableView.dequeueReusableCell(with: header, for: indexPath)
        }
    }
}
