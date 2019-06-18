import UIKit
import RxCocoa
import RxSwift

protocol TransactionDetailsDisplayLogic: class {
    func displayViewDidLoad(viewModel: TransactionDetails.Event.ViewDidLoad.ViewModel)
    func displayTransactionUpdated(viewModel: TransactionDetails.Event.TransactionUpdated.ViewModel)
    func displayTransactionActionsDidUpdate(viewModel: TransactionDetails.Event.TransactionActionsDidUpdate.ViewModel)
    func displayTransactionAction(viewModel: TransactionDetails.Event.TransactionAction.ViewModel)
    func displaySelectedCell(viewModel: TransactionDetails.Event.SelectedCell.ViewModel)
}

extension TransactionDetails {
    typealias DisplayLogic = TransactionDetailsDisplayLogic
    
    class ViewController: UIViewController {
        
        // MARK: - Private properties
        
        private let tableView: UITableView = UITableView(frame: .zero, style: .grouped)
        private let disposeBag: DisposeBag = DisposeBag()
        
        private var sections: [Model.SectionViewModel] = []
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        
        func inject(interactorDispatch: InteractorDispatch?, routing: Routing?) {
            self.interactorDispatch = interactorDispatch
            self.routing = routing
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupTableView() {
            let cellClasses: [CellViewAnyModel.Type] = [
                TransactionDetailsCell.Model.self
            ]
            self.tableView.register(classes: cellClasses)
            self.tableView.dataSource = self
            self.tableView.delegate = self
            self.tableView.rowHeight = UITableView.automaticDimension
            self.tableView.estimatedRowHeight = 125
            self.tableView.separatorStyle = .none
        }
        
        private func setupLayout() {
            self.view.addSubview(self.tableView)
            
            self.tableView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
        
        private func reloadTableView() {
            self.tableView.reloadData()
        }
        
        // MARK: - Overridden
        
        override func viewDidLoad() {
            super.viewDidLoad()
            self.setupView()
            self.setupTableView()
            
            self.setupLayout()
            
            let request = TransactionDetails.Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
    }
}

extension TransactionDetails.ViewController: TransactionDetails.DisplayLogic {
    func displayViewDidLoad(viewModel: TransactionDetails.Event.ViewDidLoad.ViewModel) { }
    
    func displayTransactionUpdated(viewModel: TransactionDetails.Event.TransactionUpdated.ViewModel) {
        switch viewModel {
        case .loading:
            self.routing?.showProgress()
        case .loaded:
            self.routing?.hideProgress()
        case .succeeded(let sectionViewModels):
            self.sections = sectionViewModels
            self.reloadTableView()
        }
    }
    
    func displayTransactionActionsDidUpdate(viewModel: TransactionDetails.Event.TransactionActionsDidUpdate.ViewModel) {
        self.navigationItem.rightBarButtonItems = viewModel.rightItems.map({ (item) -> UIBarButtonItem in
            let barItem = UIBarButtonItem(
                image: item.icon,
                style: .plain,
                target: nil,
                action: nil
            )
            barItem.rx
                .tap
                .asDriver()
                .drive(onNext: { [weak self] in
                    let onSelect: ((Int) -> Void) = { [weak self] _ in
                        self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                            let request = TransactionDetails.Event.TransactionAction.Request(id: item.id)
                            businessLogic.onTransactionAction(request: request)
                        })
                    }
                    self?.routing?.showDialog(
                        item.title,
                        item.message,
                        [Localized(.ok)],
                        onSelect
                    )
                })
                .disposed(by: self.disposeBag)
            return barItem
        })
    }
    
    func displayTransactionAction(viewModel: TransactionDetails.Event.TransactionAction.ViewModel) {
        switch viewModel {
        case .success:
            self.routing?.successAction()
        case .loaded:
            self.routing?.hideProgress()
        case .loading:
            self.routing?.showProgress()
        case .error(let error):
            self.routing?.showError(error)
        }
    }
    
    func displaySelectedCell(viewModel: TransactionDetails.Event.SelectedCell.ViewModel) {
        self.routing?.showMessage(viewModel.message)
    }
}

extension TransactionDetails.ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = self.sections[indexPath.section].cells[indexPath.row]
        let request = TransactionDetails.Event.SelectedCell.Request(model: model)
        self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
            businessLogic.onSelectedCell(request: request)
        })
    }
}

extension TransactionDetails.ViewController: UITableViewDataSource {
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
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section].title
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return self.sections[section].description
    }
}
