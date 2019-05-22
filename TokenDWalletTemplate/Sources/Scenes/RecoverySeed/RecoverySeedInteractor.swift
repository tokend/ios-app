import UIKit

protocol RecoverySeedBusinessLogic {
    func onViewDidLoad(request: RecoverySeed.Event.ViewDidLoad.Request)
    func onValidationSeedEditing(request: RecoverySeed.Event.ValidationSeedEditing.Request)
    func onCopyAction(request: RecoverySeed.Event.CopyAction.Request)
    func onProceedAction(request: RecoverySeed.Event.ProceedAction.Request)
    func onSignUpAction(request: RecoverySeed.Event.SignUpAction.Request)
}

extension RecoverySeed {
    typealias BusinessLogic = RecoverySeedBusinessLogic
    
    class Interactor {
        
        private let presenter: PresentationLogic
        private let signUpWorker: SignUpWorkerProtocol
        private var sceneModel: Model.SceneModel
        
        init(
            presenter: PresentationLogic,
            signUpWorker: SignUpWorkerProtocol,
            seed: String
            ) {
            
            self.presenter = presenter
            self.signUpWorker = signUpWorker
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
        
        let response = RecoverySeed.Event.CopyAction.Response(
            message: Localized(.recovery_seed_is_copied_to_pasteboard)
        )
        self.presenter.presentCopyAction(response: response)
    }
    
    func onProceedAction(request: RecoverySeed.Event.ProceedAction.Request) {
        let response = RecoverySeed.Event.ShowWarning.Response()
        self.presenter.presentShowWarning(response: response)
    }
    
    func onSignUpAction(request: RecoverySeed.Event.SignUpAction.Request) {
        self.presenter.presentSignUpAction(response: .loading)
        self.signUpWorker.signUp(
            completion: { [weak self] (result) in
                self?.presenter.presentSignUpAction(response: .loaded)
                let response: RecoverySeed.Event.SignUpAction.Response
                switch result {
                case .failure(let error):
                    response = .error(error)
                    
                case .success(let account, let walletData):
                    response = .success(account: account, walletData: walletData)
                }
                self?.presenter.presentSignUpAction(response: response)
        })
    }
}
