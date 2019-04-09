import Foundation
import RxSwift
import RxCocoa

protocol SettingsBusinessLogic {
    
    typealias Event = Settings.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onDidSelectCell(request: Event.DidSelectCell.Request)
    func onDidSelectSwitch(request: Event.DidSelectSwitch.Request)
    func onDidSelectAction(request: Event.DidSelectAction.Request)
}

extension Settings {
    typealias BusinessLogic = SettingsBusinessLogic
    
    class Interactor {
        
        private var sceneModel: Model.SceneModel
        
        private var sectionsProvider: SectionsProvider
        private let presenter: PresentationLogic
        
        private let disposeBag = DisposeBag()
        
        init(
            sceneModel: Model.SceneModel,
            sectionsProvider: SectionsProvider,
            presenter: PresentationLogic
            ) {
            
            self.sceneModel = sceneModel
            self.sectionsProvider = sectionsProvider
            self.presenter = presenter
        }
    }
}

extension Settings.Interactor: Settings.BusinessLogic {
    
    typealias Event = Settings.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        self.sectionsProvider.observeSections()
            .subscribe(onNext: { [weak self] sections in
                self?.sceneModel.sections = sections
                
                let response = Event.SectionsUpdated.Response(sectionModels: sections)
                self?.presenter.presentSectionsUpdated(response: response)
            })
            .disposed(by: self.disposeBag)
    }
    
    func onDidSelectCell(request: Event.DidSelectCell.Request) {
        switch request.cellIdentifier {
            
        case .fees:
            let response = Event.ShowFees.Response()
            self.presenter.presentShowFees(response: response)
            
        case .signOut:
            let response = Event.SignOut.Response()
            self.presenter.presentSignOut(response: response)
            
        case .termsOfService:
            guard let termsUrl = self.sceneModel.termsUrl else {
                return
            }
            let response = Event.ShowTerms.Response(url: termsUrl)
            self.presenter.presentShowTerms(response: response)
            
        case .accountId,
             .seed,
             .tfa,
             .biometrics,
             .verification,
             .changePassword,
             .licenses:
            
            let response = Event.DidSelectCell.Response(
                cellIdentifier: request.cellIdentifier
            )
            self.presenter.presentDidSelectCell(response: response)
        }
    }
    
    func onDidSelectSwitch(request: Event.DidSelectSwitch.Request) {
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
    
    func onDidSelectAction(request: Event.DidSelectAction.Request) {
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
