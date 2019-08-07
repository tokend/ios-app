import Foundation
import RxSwift
import RxCocoa

protocol SettingsBusinessLogic {
    func onViewDidLoad(request: Settings.Event.ViewDidLoad.Request)
    func onDidSelectCell(request: Settings.Event.DidSelectCell.Request)
    func onDidSelectSwitch(request: Settings.Event.DidSelectSwitch.Request)
    func onDidSelectAction(request: Settings.Event.DidSelectAction.Request)
}

extension Settings {
    typealias BusinessLogic = SettingsBusinessLogic
    
    class Interactor {
        
        private var sceneModel = Model.SceneModel.empty()
        
        private var sectionsProvider: SectionsProvider
        private let presenter: PresentationLogic
        
        private let disposeBag = DisposeBag()
        
        init(sectionsProvider: SectionsProvider,
             presenter: PresentationLogic
            ) {
            self.sectionsProvider = sectionsProvider
            self.presenter = presenter
        }
    }
}

extension Settings.Interactor: Settings.BusinessLogic {
    func onViewDidLoad(request: Settings.Event.ViewDidLoad.Request) {
        self.sectionsProvider.observeSections()
            .subscribe(onNext: { [weak self] sections in
                self?.sceneModel.sections = sections
                
                let response = Settings.Event.SectionsUpdated.Response(sectionModels: sections)
                self?.presenter.presentSectionsUpdated(response: response)
            })
            .disposed(by: self.disposeBag)
    }
    
    func onDidSelectCell(request: Settings.Event.DidSelectCell.Request) {
        let response = Settings.Event.DidSelectCell.Response(
            cellIdentifier: request.cellIdentifier
        )
        self.presenter.presentDidSelectCell(response: response)
    }
    
    func onDidSelectSwitch(request: Settings.Event.DidSelectSwitch.Request) {
        self.sectionsProvider.handleBoolCell(
            cellIdentifier: request.cellIdentifier,
            state: request.state,
            startLoading: { [weak self] in
                self?.presenter.presentDidSelectSwitch(response: .loading)
            },
            stopLoading: { [weak self] in
                self?.presenter.presentDidSelectSwitch(response: .loaded)
            },
            completion: { [weak self] (result) in
                switch result {
                    
                case .failed(let error):
                    self?.presenter.presentDidSelectSwitch(response: .failed(error))
                    
                case .succeded:
                    self?.presenter.presentDidSelectSwitch(response: .succeeded)
                }
        })
    }
    
    func onDidSelectAction(request: Settings.Event.DidSelectAction.Request) {
        self.sectionsProvider.handleActionCell(
            cellIdentifier: request.cellIdentifier,
            startLoading: { [weak self] in
                self?.presenter.presentDidSelectSwitch(response: .loading)
            },
            stopLoading: { [weak self] in
                self?.presenter.presentDidSelectSwitch(response: .loaded)
            },
            completion: { [weak self] (result) in
                switch result {
                    
                case .failed(let error):
                    self?.presenter.presentDidSelectSwitch(response: .failed(error))
                    
                case .succeeded:
                    self?.presenter.presentDidSelectSwitch(response: .succeeded)
                }
        })
    }
}
