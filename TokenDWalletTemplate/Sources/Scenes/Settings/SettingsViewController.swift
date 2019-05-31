import UIKit
import RxSwift

protocol SettingsDisplayLogic: class {
    
    typealias Event = Settings.Event
    
    func displaySectionsUpdated(viewModel: Settings.Event.SectionsUpdated.ViewModel)
    func displayDidSelectCell(viewModel: Settings.Event.DidSelectCell.ViewModel)
    func displayDidSelectSwitch(viewModel: Settings.Event.DidSelectSwitch.ViewModel)
    func displayShowFees(viewModel: Event.ShowFees.ViewModel)
    func displayShowTerms(viewModel: Event.ShowTerms.ViewModel)
    func displaySignOut(viewModel: Event.SignOut.ViewModel)
}

extension Settings {
    typealias DisplayLogic = SettingsDisplayLogic
    
    class ViewController: UIViewController {
        
        // MARK: - Private properties
        
        private let tableView: UITableView = UITableView(frame: .zero, style: .grouped)
        private let appVersionLabel: UILabel = UILabel()
        
        private var sections: [Model.SectionViewModel] = []
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
            self.setupAppVersionLabel()
            
            self.setupLayout()
            
            let request = Settings.Event.ViewDidLoad.Request()
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
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.containerBackgroundColor
        }
        
        private func setupTableView() {
            let cellClasses: [CellViewAnyModel.Type] = [
                SettingsPushCell.Model.self,
                SettingsBoolCell.Model.self,
                SettingsLoadingCell.Model.self,
                SettingsActionCell.Model.self
            ]
            self.tableView.register(classes: cellClasses)
            self.tableView.dataSource = self
            self.tableView.delegate = self
            self.tableView.rowHeight = UITableView.automaticDimension
            self.tableView.estimatedRowHeight = 125
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
        
        private func setupAppVersionLabel() {
            let appShortVersion: String = Bundle.main.shortVersion ?? ""
            let appBundleVersion: String = Bundle.main.bundleVersion ?? ""
            let appVersion: String
            if appBundleVersion.isEmpty {
                appVersion = appShortVersion
            } else {
                appVersion = "v\(appShortVersion) (\(appBundleVersion))"
            }
            
            self.appVersionLabel.font = Theme.Fonts.smallTextFont
            self.appVersionLabel.textColor = Theme.Colors.sideTextOnContainerBackgroundColor
            self.appVersionLabel.textAlignment = .center
            
            self.appVersionLabel.text = appVersion
        }
        
        private func setupLayout() {
            self.view.addSubview(self.tableView)
            self.view.addSubview(self.appVersionLabel)
            
            self.appVersionLabel.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.bottom.equalTo(self.view.safeArea.bottom).inset(20.0)
            }
            
            self.tableView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
        
        private func reloadTableView() {
            self.tableView.reloadData()
        }
    }
}

extension Settings.ViewController: Settings.DisplayLogic {
    
    typealias Event = Settings.Event
    
    func displaySectionsUpdated(viewModel: Settings.Event.SectionsUpdated.ViewModel) {
        self.sections = viewModel.sectionViewModels
        self.reloadTableView()
    }
    
    func displayDidSelectCell(viewModel: Settings.Event.DidSelectCell.ViewModel) {
        self.routing?.onCellSelected(viewModel.cellIdentifier)
    }
    
    func displayDidSelectSwitch(viewModel: Settings.Event.DidSelectSwitch.ViewModel) {
        
        switch viewModel {
        case .loading:
            self.routing?.showProgress()
        case .loaded:
            self.routing?.hideProgress()
        case .succeeded:
            // ignore
            break
        case .failed(let error):
            self.routing?.showErrorMessage(error)
        }
    }
    
    func displayShowFees(viewModel: Event.ShowFees.ViewModel) {
        self.routing?.onShowFees()
    }
    
    func displayShowTerms(viewModel: Event.ShowTerms.ViewModel) {
        self.routing?.onShowTerms(viewModel.url)
    }
    
    func displaySignOut(viewModel: Event.SignOut.ViewModel) {
        self.routing?.onSignOut()
    }
}

extension Settings.ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cellModel = self.sections[indexPath.section].cells[indexPath.row]
        
        guard let model = cellModel as? SettingsPushCell.Model else {
            return
        }
        let request = Settings.Event.DidSelectCell.Request(cellIdentifier: model.identifier)
        self.interactorDispatch?.sendRequest { businessLogic in
            businessLogic.onDidSelectCell(request: request)
        }
    }
}

extension Settings.ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.sections[indexPath.section].cells[indexPath.row]
        let cell = tableView.dequeueReusableCell(with: model, for: indexPath)
        if model is SettingsPushCell.Model {
            cell.selectionStyle = UITableViewCell.SelectionStyle.blue
        }
        
        if let cell = cell as? SettingsBoolCell.View {
            cell.didSwitch = { [weak self] (value) in
                guard let model = model as? SettingsBoolCell.Model else {
                    return
                }
                let request = Settings.Event.DidSelectSwitch.Request(cellIdentifier: model.identifier, state: value)
                self?.interactorDispatch?.sendRequest { (businessLogic) in
                    businessLogic.onDidSelectSwitch(request: request)
                }
            }
        } else if let cell = cell as? SettingsActionCell.View {
            cell.onAction = { [weak self] in
                guard let model = model as? SettingsActionCell.Model else {
                    return
                }
                let request = Settings.Event.DidSelectAction.Request(cellIdentifier: model.identifier)
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onDidSelectAction(request: request)
                })
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
