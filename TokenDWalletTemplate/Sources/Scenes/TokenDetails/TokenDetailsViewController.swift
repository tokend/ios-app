import UIKit
import RxSwift

protocol TokenDetailsDisplayLogic: class {
    func displayTokenDidUpdate(viewModel: TokenDetailsScene.Event.TokenDidUpdate.ViewModel)
    func displayDidSelectAction(viewModel: TokenDetailsScene.Event.DidSelectAction.ViewModel)
}

extension TokenDetailsScene {
    typealias DisplayLogic = TokenDetailsDisplayLogic
    
    class ViewController: UIViewController {
        
        // MARK: - Private properties
        
        private let tableView: UITableView = UITableView(frame: .zero, style: .grouped)
        
        private var sections: [Model.TableSection] = []
        
        private let disposeBag: DisposeBag = DisposeBag()
        
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
            let request = TokenDetailsScene.Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        // MARK: - Private
        
        private func contentOffsetUpdated(point: CGPoint) {
            if point.y > 0 {
                self.routing?.showSeparator()
            } else {
                self.routing?.hideSeparator()
            }
        }
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.containerBackgroundColor
        }
        
        private func setupTableView() {
            let cellClasses: [CellViewAnyModel.Type] = [
                ExploreTokensTableViewCell.Model.self,
                CardView.CardViewModel.self
            ]
            self.tableView.register(classes: cellClasses)
            self.tableView.dataSource = self
            self.tableView.rowHeight = UITableView.automaticDimension
            self.tableView.estimatedRowHeight = 125
            self.tableView.separatorStyle = .none
            self.tableView.rx
                .contentOffset
                .asDriver()
                .throttle(0.25)
                .drive(onNext: { [weak self] (offset) in
                    self?.contentOffsetUpdated(point: offset)
                })
                .disposed(by: self.disposeBag)
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
    }
}

extension TokenDetailsScene.ViewController: TokenDetailsScene.DisplayLogic {
    func displayTokenDidUpdate(viewModel: TokenDetailsScene.Event.TokenDidUpdate.ViewModel) {
        switch viewModel {
        case .empty:
            self.sections = []
        case .sections(let sections):
            self.sections = sections
        }
        self.reloadTableView()
    }
    
    func displayDidSelectAction(viewModel: TokenDetailsScene.Event.DidSelectAction.ViewModel) {
        switch viewModel {
        case .viewHistory(let identifier):
            self.routing?.onDidSelectHistoryForBalance(identifier)
        }
    }
}

extension TokenDetailsScene.ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.sections[indexPath.section].cells[indexPath.row]
        let cell = tableView.dequeueReusableCell(with: model, for: indexPath)
        if let cell = cell as? ExploreTokensTableViewCell.View,
            model is ExploreTokensTableViewCell.Model {
            cell.onActionButtonClicked = { [weak self] (cell) in
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    let request = TokenDetailsScene.Event.DidSelectAction.Request()
                    businessLogic.onDidSelectAction(request: request)
                })
            }
        } else if let cell = cell as? TokenDetailsScene.CardView.View {
            cell.didSelectCell = { [weak self] (model) in
                if let model = model as? TokenDetailsTokenDocumentCell.Model {
                    self?.routing?.onDidSelectDocument(model.link)
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section].title
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return self.sections[section].description
    }
}
