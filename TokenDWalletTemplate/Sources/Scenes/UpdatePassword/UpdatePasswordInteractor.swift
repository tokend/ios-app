import Foundation

protocol UpdatePasswordBusinessLogic {
    func onViewDidLoadSync(request: UpdatePassword.Event.ViewDidLoadSync.Request)
    func onSubmitAction(request: UpdatePassword.Event.SubmitAction.Request)
    func onFieldEditing(request: UpdatePassword.Event.FieldEditing.Request)
}

extension UpdatePassword {
    typealias BusinessLogic = UpdatePasswordBusinessLogic
    
    class Interactor {
        
        private var sceneModel: Model.SceneModel
        private let submitPasswordHandler: SubmitPasswordHandler
        private let presenter: PresentationLogic
        
        init(
            presenter: PresentationLogic,
            sceneModel: Model.SceneModel,
            submitPasswordHandler: SubmitPasswordHandler
            ) {
            
            self.presenter = presenter
            self.sceneModel = sceneModel
            self.submitPasswordHandler = submitPasswordHandler
        }
        
        // MARK: -
        
        private func handleFieldEditing(fieldType: Model.FieldType, value: String?) {
            let field = self.sceneModel.fields.first(where: { (field) in
                return field.type == fieldType
            })
            
            field?.value = value
        }
        
        private func handleSubmitAction() {
            self.submitPasswordHandler.submitFields(
                self.sceneModel.fields,
                startLoading: { [weak self] in
                    self?.presenter.presentSubmitAction(response: .loading)
                },
                stopLoading: { [weak self] in
                    self?.presenter.presentSubmitAction(response: .loaded)
                },
                completion: { [weak self] (result) in
                    switch result {
                        
                    case .failed(let error):
                        self?.presenter.presentSubmitAction(response: .failed(error))
                        
                    case .succeeded:
                        self?.presenter.presentSubmitAction(response: .succeeded)
                    }
            })
        }
    }
}

extension UpdatePassword.Interactor: UpdatePassword.BusinessLogic {
    func onViewDidLoadSync(request: UpdatePassword.Event.ViewDidLoadSync.Request) {
        let response = UpdatePassword.Event.ViewDidLoadSync.Response(
            fields: self.sceneModel.fields
        )
        self.presenter.presentViewDidLoadSync(response: response)
    }
    
    func onSubmitAction(request: UpdatePassword.Event.SubmitAction.Request) {
        self.handleSubmitAction()
    }
    
    func onFieldEditing(request: UpdatePassword.Event.FieldEditing.Request) {
        self.handleFieldEditing(fieldType: request.fieldType, value: request.text)
    }
}
