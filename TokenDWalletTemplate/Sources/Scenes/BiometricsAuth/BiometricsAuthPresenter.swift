import Foundation

protocol BiometricsAuthPresentationLogic {
    func presentViewDidAppear(response: BiometricsAuth.Event.ViewDidAppear.Response)
}

extension BiometricsAuth {
    typealias PresentationLogic = BiometricsAuthPresentationLogic
    
    struct Presenter {
        
        private let presenterDispatch: PresenterDispatch
        
        init(presenterDispatch: PresenterDispatch) {
            self.presenterDispatch = presenterDispatch
        }
    }
}

extension BiometricsAuth.Presenter: BiometricsAuth.PresentationLogic {
    func presentViewDidAppear(response: BiometricsAuth.Event.ViewDidAppear.Response) {
        let viewModel: BiometricsAuth.Event.ViewDidAppear.ViewModel
        
        switch response.result {
            
        case .failure:
            viewModel = .failure
            
        case .success(let account):
            viewModel = .success(account: account)
            
        case .userCancel:
            viewModel = .userCancel
            
        case .userFallback:
            viewModel = .userFallback
        }
        
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayViewDidAppear(viewModel: viewModel)
        }
    }
}
