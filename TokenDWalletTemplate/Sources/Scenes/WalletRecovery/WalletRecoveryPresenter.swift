import Foundation

protocol WalletRecoveryPresentationLogic {
    func presentViewDidLoad(response: WalletRecovery.Event.ViewDidLoad.Response)
}

extension WalletRecovery {
    typealias PresentationLogic = WalletRecoveryPresentationLogic
    
    struct Presenter {
        
        private let presenterDispatch: PresenterDispatch
        
        init(presenterDispatch: PresenterDispatch) {
            self.presenterDispatch = presenterDispatch
        }
    }
}

extension WalletRecovery.Presenter: WalletRecovery.PresentationLogic {
    func presentViewDidLoad(response: WalletRecovery.Event.ViewDidLoad.Response) {
        let viewModel = WalletRecovery.Event.ViewDidLoad.ViewModel()
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayViewDidLoad(viewModel: viewModel)
        }
    }
}
