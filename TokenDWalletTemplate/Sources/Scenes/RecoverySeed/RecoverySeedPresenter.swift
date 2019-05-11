import Foundation

protocol RecoverySeedPresentationLogic {
    func presentViewDidLoad(response: RecoverySeed.Event.ViewDidLoad.Response)
    func presentValidationSeedEditing(response: RecoverySeed.Event.ValidationSeedEditing.Response)
    func presentCopyAction(response: RecoverySeed.Event.CopyAction.Response)
    func presentShowWarning(response: RecoverySeed.Event.ShowWarning.Response)
    func presentSignUpAction(response: RecoverySeed.Event.SignUpAction.Response)
}

extension RecoverySeed {
    typealias PresentationLogic = RecoverySeedPresentationLogic
    
    struct Presenter {
        
        private let presenterDispatch: PresenterDispatch
        
        init(presenterDispatch: PresenterDispatch) {
            self.presenterDispatch = presenterDispatch
        }
    }
}

extension RecoverySeed.Presenter: RecoverySeed.PresentationLogic {
    func presentViewDidLoad(response: RecoverySeed.Event.ViewDidLoad.Response) {
        let viewModel = RecoverySeed.Event.ViewDidLoad.ViewModel(
            seed: response.seed,
            inputSeedValid: response.inputSeedValid
        )
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayViewDidLoad(viewModel: viewModel)
        }
    }
    
    func presentValidationSeedEditing(response: RecoverySeed.Event.ValidationSeedEditing.Response) {
        let viewModel = RecoverySeed.Event.ValidationSeedEditing.ViewModel(inputSeedValid: response.inputSeedValid)
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayValidationSeedEditing(viewModel: viewModel)
        }
    }
    
    func presentCopyAction(response: RecoverySeed.Event.CopyAction.Response) {
        let viewModel = RecoverySeed.Event.CopyAction.ViewModel(message: response.message)
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayCopyAction(viewModel: viewModel)
        }
    }
    
    func presentShowWarning(response: RecoverySeed.Event.ShowWarning.Response) {
        let viewModel = response
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayShowWarning(viewModel: viewModel)
        }
    }
    
    func presentSignUpAction(response: RecoverySeed.Event.SignUpAction.Response) {
        let viewModel: RecoverySeed.Event.SignUpAction.ViewModel
        
        switch response {
            
        case .loading:
            viewModel = .loading
        case .loaded:
            viewModel = .loaded
        case .success(let account, let walletData):
            viewModel = .success(account: account, walletData: walletData)
        case .error(let error):
            viewModel = .error(error.localizedDescription)
        }
        
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySignUpAction(viewModel: viewModel)
        }
    }
}
