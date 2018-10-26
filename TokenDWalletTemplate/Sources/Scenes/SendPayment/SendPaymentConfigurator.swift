import Foundation

extension SendPayment {
    
    enum Configurator {
        static func configure(
            viewController: ViewController,
            senderAccountId: String,
            balanceDetailsLoader: BalanceDetailsLoader,
            amountFormatter: AmountFormatterProtocol,
            recipientAddressResolver: RecipientAddressResolver,
            feeLoader: FeeLoaderProtocol,
            feeType: SendPayment.Model.FeeType,
            operation: SendPayment.Model.Operation,
            viewConfig: Model.ViewConfig,
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
                balanceDetailsLoader: balanceDetailsLoader,
                recipientAddressResolver: recipientAddressResolver,
                feeLoader: feeLoader
            )
            let interactorDispatch = InteractorDispatch(
                queue: queue,
                businessLogic: interactor
            )
            viewController.inject(
                interactorDispatch: interactorDispatch,
                routing: routing,
                viewConfig: viewConfig
            )
        }
    }
}

extension SendPayment {
    
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
