import Foundation

protocol VerifyEmailBusinessLogic {
    func onViewDidLoad(request: VerifyEmail.Event.ViewDidLoad.Request)
    func onResendEmail(request: VerifyEmail.Event.ResendEmail.Request)
}

extension VerifyEmail {
    typealias BusinessLogic = VerifyEmailBusinessLogic
    typealias ResendWorker = VerifyEmailResendWorkerProtocol
    typealias VerifyWorker = VerifyEmailVerifyWorkerProtocol
    
    class Interactor {
        
        private let presenter: PresentationLogic
        private let appController: AppControllerProtocol
        private let resendWorker: ResendWorker
        private let verifyWorker: VerifyWorker
        private let launchOptionsUrl: URL?
        
        init(
            presenter: PresentationLogic,
            appController: AppControllerProtocol,
            resendWorker: ResendWorker,
            verifyWorker: VerifyWorker,
            launchOptionsUrl: URL?
            ) {
            
            self.presenter = presenter
            self.appController = appController
            self.resendWorker = resendWorker
            self.verifyWorker = verifyWorker
            self.launchOptionsUrl = launchOptionsUrl
        }
        
        // MARK: - Private
        
        private func handle(url: URL) -> Bool {
            guard let token = self.verifyWorker.verifyEmailTokenFrom(url: url) else {
                return false
            }
            
            self.presenter.presentVerifyToken(response: .loading)
            self.verifyWorker.performVerifyRequest(token: token, completion: { [weak self] (result) in
                self?.presenter.presentVerifyToken(response: .loaded)
                
                switch result {
                    
                case .failed(let error):
                    let response = VerifyEmail.Event.VerifyToken.Response.failed(error)
                    self?.presenter.presentVerifyToken(response: response)
                    
                case .succeded:
                    let response = VerifyEmail.Event.VerifyToken.Response.succeded
                    self?.presenter.presentVerifyToken(response: response)
                }
            })
            
            return true
        }
    }
}

extension VerifyEmail.Interactor: VerifyEmail.BusinessLogic {
    func onViewDidLoad(request: VerifyEmail.Event.ViewDidLoad.Request) {
        self.appController.addUserAcivity(subscriber: UserActivitySubscriber.urlHandler(
            responder: self, { [weak self] (url) -> Bool in
                guard let strongSelf = self else {
                    return false
                }
                
                return strongSelf.handle(url: url)
        }))
        
        if let launchOptionsUrl = self.launchOptionsUrl, self.handle(url: launchOptionsUrl) {
            self.appController.launchOptionsUrlHandled(url: launchOptionsUrl)
        } else if let lastURL = self.appController.getLastUserActivityWebLink(), self.handle(url: lastURL) {
            self.appController.lastUserActivityWebLinkHandled(url: lastURL)
        }
    }
    
    func onResendEmail(request: VerifyEmail.Event.ResendEmail.Request) {
        self.presenter.presentResendEmail(response: .loading)
        self.resendWorker.performResendRequest(completion: { [weak self] (result) in
            self?.presenter.presentResendEmail(response: .loaded)
            
            switch result {
                
            case .failed(let error):
                self?.presenter.presentResendEmail(response: .failed(error))
                
            case .succeded:
                break
            }
        })
    }
}
