import UIKit
import RxSwift

protocol SalesDisplayLogic: class {
    func displaySectionsUpdated(viewModel: Sales.Event.SectionsUpdated.ViewModel)
    func displayLoadingStatusDidChange(viewModel: Sales.Event.LoadingStatusDidChange.ViewModel)
    func displayEmptyResult(viewModel: Sales.Event.EmptyResult.ViewModel)
}

extension Sales {
    typealias DisplayLogic = SalesDisplayLogic
    
    class ViewController: UIViewController {
        
        // MARK: - Private properties
        
        private let tableView: UITableView = UITableView(frame: .zero, style: .grouped)
        private let emptyView: UILabel = SharedViewsBuilder.createEmptyLabel()
        private var sections: [Model.SectionViewModel] = []
        
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
            
            let request = Sales.Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        // MARK: - Private
        
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
                image: #imageLiteral(resourceName: "Pending icon"),
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
            self.tableView.rowHeight = UITableViewAutomaticDimension
            self.tableView.estimatedRowHeight = 380.0
            self.tableView.refreshControl = self.refreshControl
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
            self.routing?.onHideLoading()
            
        case .loading:
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
        
        self.routing?.onDidSelectSale(saleModel.saleIdentifier)
    }
}
