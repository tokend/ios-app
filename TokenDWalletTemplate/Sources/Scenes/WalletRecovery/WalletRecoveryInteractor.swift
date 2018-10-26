import Foundation

protocol WalletRecoveryBusinessLogic {
    func onViewDidLoad(request: WalletRecovery.Event.ViewDidLoad.Request)
}

extension WalletRecovery {
    typealias BusinessLogic = WalletRecoveryBusinessLogic
    
    class Interactor {
        
        private let presenter: PresentationLogic
        
        init(presenter: PresentationLogic) {
            self.presenter = presenter
        }
    }
}

extension WalletRecovery.Interactor: WalletRecovery.BusinessLogic {
    func onViewDidLoad(request: WalletRecovery.Event.ViewDidLoad.Request) {
        let response = WalletRecovery.Event.ViewDidLoad.Response()
        self.presenter.presentViewDidLoad(response: response)
    }
}
