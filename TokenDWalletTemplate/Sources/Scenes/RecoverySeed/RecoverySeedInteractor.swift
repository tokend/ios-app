import UIKit

protocol RecoverySeedBusinessLogic {
    func onViewDidLoad(request: RecoverySeed.Event.ViewDidLoad.Request)
    func onValidationSeedEditing(request: RecoverySeed.Event.ValidationSeedEditing.Request)
    func onCopyAction(request: RecoverySeed.Event.CopyAction.Request)
    func onProceedAction(request: RecoverySeed.Event.ProceedAction.Request)
}

extension RecoverySeed {
    typealias BusinessLogic = RecoverySeedBusinessLogic
    
    class Interactor {
        
        private let presenter: PresentationLogic
        private var sceneModel: Model.SceneModel
        
        init(
            presenter: PresentationLogic,
            seed: String
            ) {
            
            self.presenter = presenter
            self.sceneModel = Model.SceneModel(
                seed: seed,
                userInputSeed: nil
            )
        }
        
        // MARK: - Private
        
        private func isInputSeedValid() -> Model.InputSeedValidation {
            guard let inputSeed = self.sceneModel.userInputSeed, inputSeed.count > 0 else {
                return .empty
            }
            
            let isEqual = self.sceneModel.seed.caseInsensitiveCompare(inputSeed) == .orderedSame
            
            return isEqual ? .valid : .invalid
        }
    }
}

extension RecoverySeed.Interactor: RecoverySeed.BusinessLogic {
    func onViewDidLoad(request: RecoverySeed.Event.ViewDidLoad.Request) {
        let inputSeedValid = self.isInputSeedValid()
        let response = RecoverySeed.Event.ViewDidLoad.Response(
            seed: self.sceneModel.seed,
            inputSeedValid: inputSeedValid
        )
        self.presenter.presentViewDidLoad(response: response)
    }
    
    func onValidationSeedEditing(request: RecoverySeed.Event.ValidationSeedEditing.Request) {
        self.sceneModel.userInputSeed = request.value
        
        let inputSeedValid = self.isInputSeedValid()
        let response = RecoverySeed.Event.ValidationSeedEditing.Response(inputSeedValid: inputSeedValid)
        self.presenter.presentValidationSeedEditing(response: response)
    }
    
    func onCopyAction(request: RecoverySeed.Event.CopyAction.Request) {
        UIPasteboard.general.string = self.sceneModel.seed
        
        let response = RecoverySeed.Event.CopyAction.Response(message: "Recovery seed is copied to pasteboard")
        self.presenter.presentCopyAction(response: response)
    }
    
    func onProceedAction(request: RecoverySeed.Event.ProceedAction.Request) {
        let response = RecoverySeed.Event.ProceedAction.Response.showMessage
        self.presenter.presentProceedAction(response: response)
    }
}
