import UIKit
import RxSwift
import RxCocoa

protocol ConfirmationSceneDisplayLogic: class {
    func displayViewDidLoad(viewModel: ConfirmationScene.Event.ViewDidLoad.ViewModel)
    func displaySectionsUpdated(viewModel: ConfirmationScene.Event.SectionsUpdated.ViewModel)
    func displayConfirmAction(viewModel: ConfirmationScene.Event.ConfirmAction.ViewModel)
}

extension ConfirmationScene {
    typealias DisplayLogic = ConfirmationSceneDisplayLogic
    
    class ViewController: UIViewController {
        typealias Event = ConfirmationScene.Event
        
        // MARK: - Private properties
        
        private let tableView: UITableView = UITableView(frame: .zero, style: .grouped)
        
        private var sections: [Model.SectionViewModel] = []
        
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
            self.setupTableView()
            self.setupConfirmActionButton()
            self.setupLayout()
            
            let request = ConfirmationScene.Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        // MARK: - Setup
        
        private func setupView() {
            
        }
        
        private func setupTableView() {
            self.tableView.backgroundColor = Theme.Colors.containerBackgroundColor
            self.tableView.register(classes: [
                View.TitleTextViewModel.self,
                View.TitleBoolSwitchViewModel.self
                ])
            self.tableView.delegate = self
            self.tableView.dataSource = self
        }
        
        private func setupConfirmActionButton() {
            let button = UIBarButtonItem(image: #imageLiteral(resourceName: "Checkmark"), style: .plain, target: nil, action: nil)
            button.rx
                .tap
                .asDriver()
                .drive(onNext: { [weak self] in
                    self?.view.endEditing(true)
                    let request = Event.ConfirmAction.Request()
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onConfirmAction(request: request)
                    })
                })
                .disposed(by: self.disposeBag)
            self.navigationItem.rightBarButtonItem = button
        }
        
        private func setupLayout() {
            self.view.addSubview(self.tableView)
            
            self.tableView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }
}

extension ConfirmationScene.ViewController: ConfirmationScene.DisplayLogic {
    func displayViewDidLoad(viewModel: ConfirmationScene.Event.ViewDidLoad.ViewModel) {
        
    }
    
    func displaySectionsUpdated(viewModel: ConfirmationScene.Event.SectionsUpdated.ViewModel) {
        self.sections = viewModel.sectionViewModels
        self.tableView.reloadData()
    }
    
    func displayConfirmAction(viewModel: ConfirmationScene.Event.ConfirmAction.ViewModel) {
        switch viewModel {
            
        case .loading:
            self.routing?.onShowProgress()
            
        case .loaded:
            self.routing?.onHideProgress()
            
        case .failed(let errorMessage):
            self.routing?.onShowError(errorMessage)
            
        case .succeeded:
            self.routing?.onConfirmationSucceeded()
        }
    }
}

extension ConfirmationScene.ViewController: UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
}

extension ConfirmationScene.ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.sections[indexPath.section].cells[indexPath.row]
        let cell = tableView.dequeueReusableCell(with: model, for: indexPath)
        
        if let boolSwitchCell = cell as? ConfirmationScene.View.TitleBoolSwitchView {
            boolSwitchCell.onSwitch = { [weak self] (identifier, value) in
                let request = Event.BoolSwitch.Request(
                    identifier: identifier,
                    value: value
                )
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onBoolSwitch(request: request)
                })
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section].title
    }
}
