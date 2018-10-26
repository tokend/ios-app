import Foundation

protocol VerifyEmailPresentationLogic {
    func presentResendEmail(response: VerifyEmail.Event.ResendEmail.Response)
    func presentVerifyToken(response: VerifyEmail.Event.VerifyToken.Response)
}

extension VerifyEmail {
    typealias PresentationLogic = VerifyEmailPresentationLogic
    
    struct Presenter {
        
        private let presenterDispatch: PresenterDispatch
        
        init(presenterDispatch: PresenterDispatch) {
            self.presenterDispatch = presenterDispatch
        }
    }
}

extension VerifyEmail.Presenter: VerifyEmail.PresentationLogic {
    func presentResendEmail(response: VerifyEmail.Event.ResendEmail.Response) {
        let viewModel: VerifyEmail.Event.ResendEmail.ViewModel
        
        switch response {
            
        case .failed(let error):
            viewModel = .failed(errorMessage: error.localizedDescription)
            
        case .loaded:
            viewModel = .loaded
            
        case .loading:
            viewModel = .loading
        }
        
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayResendEmail(viewModel: viewModel)
        }
    }
    
    func presentVerifyToken(response: VerifyEmail.Event.VerifyToken.Response) {
        let viewModel: VerifyEmail.Event.VerifyToken.ViewModel
        
        switch response {
            
        case .failed(let error):
            viewModel = .failed(errorMessage: error.localizedDescription)
            
        case .loaded:
            viewModel = .loaded
            
        case .loading:
            viewModel = .loading
            
        case .succeded:
            viewModel = .succeded
        }
        
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayVerifyToken(viewModel: viewModel)
        }
    }
}
