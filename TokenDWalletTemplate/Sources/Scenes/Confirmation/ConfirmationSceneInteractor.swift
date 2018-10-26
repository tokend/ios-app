import Foundation
import RxSwift

protocol ConfirmationSceneBusinessLogic {
    func onViewDidLoad(request: ConfirmationScene.Event.ViewDidLoad.Request)
    func onTextFieldEdit(request: ConfirmationScene.Event.TextFieldEdit.Request)
    func onBoolSwitch(request: ConfirmationScene.Event.BoolSwitch.Request)
    func onConfirmAction(request: ConfirmationScene.Event.ConfirmAction.Request)
}

extension ConfirmationScene {
    typealias BusinessLogic = ConfirmationSceneBusinessLogic
    typealias SectionsProvider = ConfirmationSectionsProviderProtocol
    
    class Interactor {
        
        private let presenter: PresentationLogic
        private let sectionsProvider: SectionsProvider
        private let disposeBag = DisposeBag()
        
        init(
            presenter: PresentationLogic,
            sectionsProvider: SectionsProvider
            ) {
            self.presenter = presenter
            self.sectionsProvider = sectionsProvider
        }
        
        // MARK: - Private
        
        private func observeSections() {
            self.sectionsProvider
                .observeConfirmationSections()
                .subscribe(onNext: { [weak self] sectionModels in
                    self?.onSectionsUpdated(sectionModels: sectionModels)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func onSectionsUpdated(sectionModels: [Model.SectionModel]) {
            let response = Event.SectionsUpdated.Response(sectionModels: sectionModels)
            self.presenter.presentSectionsUpdated(response: response)
        }
        
        private func loadSections() {
            self.sectionsProvider.loadConfirmationSections()
        }
        
        private func handleConfirmAction() {
            self.presenter.presentConfirmAction(response: .loading)
            
            self.sectionsProvider.handleConfirmAction(completion: { [weak self] (result) in
                self?.presenter.presentConfirmAction(response: .loaded)
                
                let response: Event.ConfirmAction.Response
                switch result {
                    
                case .failed(let error):
                    response = .failed(error)
                    
                case .succeeded:
                    response = .succeeded
                }
                self?.presenter.presentConfirmAction(response: response)
            })
        }
    }
}

extension ConfirmationScene.Interactor: ConfirmationScene.BusinessLogic {
    func onViewDidLoad(request: ConfirmationScene.Event.ViewDidLoad.Request) {
        let response = ConfirmationScene.Event.ViewDidLoad.Response()
        self.presenter.presentViewDidLoad(response: response)
        
        self.observeSections()
        self.loadSections()
    }
    
    func onTextFieldEdit(request: ConfirmationScene.Event.TextFieldEdit.Request) {
        self.sectionsProvider.handleTextEdit(
            identifier: request.identifier,
            value: request.text
        )
    }
    
    func onBoolSwitch(request: ConfirmationScene.Event.BoolSwitch.Request) {
        self.sectionsProvider.handleBoolSwitch(
            identifier: request.identifier,
            value: request.value
        )
    }
    
    func onConfirmAction(request: ConfirmationScene.Event.ConfirmAction.Request) {
        self.handleConfirmAction()
    }
}
