import Foundation

protocol BiometricsAuthBusinessLogic {
    func onViewDidAppear(request: BiometricsAuth.Event.ViewDidAppear.Request)
}

extension BiometricsAuth {
    typealias BusinessLogic = BiometricsAuthBusinessLogic
    
    class Interactor {
        
        private let presenter: PresentationLogic
        private let authWorker: AuthWorker
        
        init(
            presenter: PresentationLogic,
            authWorker: AuthWorker
            ) {
            
            self.presenter = presenter
            self.authWorker = authWorker
        }
    }
}

extension BiometricsAuth.Interactor: BiometricsAuth.BusinessLogic {
    func onViewDidAppear(request: BiometricsAuth.Event.ViewDidAppear.Request) {
        self.authWorker.performAuth(completion: { [weak self] (result) in
            let response = BiometricsAuth.Event.ViewDidAppear.Response(result: result)
            self?.presenter.presentViewDidAppear(response: response)
        })
    }
}
