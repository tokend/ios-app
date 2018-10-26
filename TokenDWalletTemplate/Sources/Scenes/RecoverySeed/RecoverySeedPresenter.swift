import Foundation

protocol RecoverySeedPresentationLogic {
    func presentViewDidLoad(response: RecoverySeed.Event.ViewDidLoad.Response)
    func presentValidationSeedEditing(response: RecoverySeed.Event.ValidationSeedEditing.Response)
    func presentCopyAction(response: RecoverySeed.Event.CopyAction.Response)
    func presentProceedAction(response: RecoverySeed.Event.ProceedAction.Response)
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
    
    func presentProceedAction(response: RecoverySeed.Event.ProceedAction.Response) {
        let viewModel: RecoverySeed.Event.ProceedAction.ViewModel
        switch response {
            
        case .proceed:
            viewModel = .proceed
            
        case .showMessage:
            viewModel = .showMessage
        }
        
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayProceedAction(viewModel: viewModel)
        }
    }
}
