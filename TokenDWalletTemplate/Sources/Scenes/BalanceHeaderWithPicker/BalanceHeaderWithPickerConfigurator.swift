import Foundation

extension BalanceHeaderWithPicker {
    
    enum Configurator {
        static func configure(
            view: View,
            sceneModel: Model.SceneModel,
            amountFormatter: AmountFormatterProtocol,
            balancesFetcher: BalancesFetcherProtocol,
            rateProvider: RateProviderProtocol,
            routing: Routing?
            ) {
            
            let presenterDispatch = PresenterDispatch(displayLogic: view)
            let presenter = Presenter(
                presenterDispatch: presenterDispatch,
                amountFormatter: amountFormatter
            )
            let interactor = Interactor(
                sceneModel: sceneModel,
                presenter: presenter,
                balancesFetcher: balancesFetcher,
                rateProvider: rateProvider
            )
            let interactorDispatch = InteractorDispatch(businessLogic: interactor)
            view.inject(interactorDispatch: interactorDispatch, routing: routing)
        }
    }
}

extension BalanceHeaderWithPicker {
    
    class InteractorDispatch {
        
        private let queue: DispatchQueue = DispatchQueue(
            label: "\(NSStringFromClass(InteractorDispatch.self))\(BusinessLogic.self)".queueLabel,
            qos: .userInteractive
        )
        
        private let businessLogic: BusinessLogic
        
        init(businessLogic: BusinessLogic) {
            self.businessLogic = businessLogic
        }
        
        func sendRequest(requestBlock: @escaping (_ businessLogic: BusinessLogic) -> Void) {
            self.queue.async {
                requestBlock(self.businessLogic)
            }
        }
        
        func sendSyncRequest<ReturnType: Any>(
            requestBlock: @escaping (_ businessLogic: BusinessLogic) -> ReturnType
            ) -> ReturnType {
            return requestBlock(self.businessLogic)
        }
    }
    
    class PresenterDispatch {
        
        private weak var displayLogic: DisplayLogic?
        
        init(displayLogic: DisplayLogic) {
            self.displayLogic = displayLogic
        }
        
        func display(displayBlock: @escaping (_ displayLogic: DisplayLogic) -> Void) {
            guard let displayLogic = self.displayLogic else { return }
            
            DispatchQueue.main.async {
                displayBlock(displayLogic)
            }
        }
        
        func displaySync(displayBlock: @escaping (_ displayLogic: DisplayLogic) -> Void) {
            guard let displayLogic = self.displayLogic else { return }
            
            displayBlock(displayLogic)
        }
    }
}
