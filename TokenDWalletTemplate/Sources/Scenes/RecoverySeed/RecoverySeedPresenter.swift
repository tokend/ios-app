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
        let seed = NSAttributedString(string: response.seed)
        let boldNever = NSAttributedString(
            string: Localized(.never),
            attributes: [
                .font: Theme.Fonts.plainBoldTextFont
            ]
        )
        let weDontKnow = NSAttributedString(
            string: Localized(.we_do_not_know_your_seed),
            attributes: [
                .font: Theme.Fonts.plainBoldTextFont
            ]
        )
        let text = LocalizedAtrributed(
            .save_this_seed_to,
            attributes: [
                .font: Theme.Fonts.plainTextFont
            ],
            replace: [
                .save_this_seed_to_replace_seed: seed,
                .save_this_seed_to_replace_never: boldNever,
                .save_this_seed_to_replace_we_do_not_know_your_seed: weDontKnow
            ])
        let viewModel = RecoverySeed.Event.ViewDidLoad.ViewModel(
            text: text,
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
