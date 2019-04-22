import Foundation

extension SendPaymentAmount {
    
    enum Configurator {
        static func configure(
            viewController: ViewController,
            senderAccountId: String,
            selectedBalanceId: String?,
            balanceDetailsLoader: BalanceDetailsLoader,
            amountFormatter: AmountFormatterProtocol,
            feeLoader: FeeLoaderProtocol,
            feeType: Model.FeeType,
            operation: Model.Operation,
            routing: Routing?
            ) {
            
            let queue: DispatchQueue = DispatchQueue(
                label: "\(NSStringFromClass(InteractorDispatch.self))\(Interactor.self)".queueLabel,
                qos: .userInteractive
            )
            
            let presenterDispatch = PresenterDispatch(displayLogic: viewController)
            let presenter = Presenter(
                presenterDispatch: presenterDispatch,
                amountFormatter: amountFormatter
            )
            let interactor = Interactor(
                presenter: presenter,
                queue: queue,
                sceneModel: Model.SceneModel(feeType: feeType, operation: operation),
                senderAccountId: senderAccountId,
                selectedBalanceId: selectedBalanceId,
                balanceDetailsLoader: balanceDetailsLoader,
                feeLoader: feeLoader
            )
            let interactorDispatch = InteractorDispatch(
                queue: queue,
                businessLogic: interactor
            )
            viewController.inject(
                interactorDispatch: interactorDispatch,
                routing: routing
            )
        }
    }
}

extension SendPaymentAmount {
    
    class InteractorDispatch {
        
        private let queue: DispatchQueue
        private let businessLogic: BusinessLogic
        
        init(queue: DispatchQueue, businessLogic: BusinessLogic) {
            self.queue = queue
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
