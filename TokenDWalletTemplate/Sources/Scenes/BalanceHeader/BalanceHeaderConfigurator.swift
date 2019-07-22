import Foundation

extension BalanceHeader {
    
    public enum Configurator {
        
        static func configure(
            view: View,
            sceneModel: Model.SceneModel,
            balanceFetcher: BalanceFetcherProtocol,
            amountFormatter: AmountFormatterProtocol,
            routing: Routing?,
            onDeinit: DeinitCompletion = nil
            ) {
            
            let presenterDispatch = PresenterDispatch(displayLogic: view)
            let presenter = Presenter(
                presenterDispatch: presenterDispatch,
                amountFormatter: amountFormatter
            )
            let interactor = Interactor(
                sceneModel: sceneModel,
                presenter: presenter,
                balanceFetcher: balanceFetcher
            )
            let interactorDispatch = InteractorDispatch(businessLogic: interactor)
            view.inject(
                interactorDispatch: interactorDispatch,
                routing: routing,
                onDeinit: onDeinit
            )
        }
    }
}

extension BalanceHeader {
    
    @objc(BalanceHeaderInteractorDispatch)
    public class InteractorDispatch: NSObject {
        
        private let queue: DispatchQueue = DispatchQueue(
            label: "\(NSStringFromClass(InteractorDispatch.self))\(BusinessLogic.self)".queueLabel,
            qos: .userInteractive
        )
        
        private let businessLogic: BusinessLogic
        
        public init(businessLogic: BusinessLogic) {
            self.businessLogic = businessLogic
        }
        
        public func sendRequest(requestBlock: @escaping (_ businessLogic: BusinessLogic) -> Void) {
            self.queue.async {
                requestBlock(self.businessLogic)
            }
        }
        
        public func sendSyncRequest<ReturnType: Any>(
            requestBlock: @escaping (_ businessLogic: BusinessLogic) -> ReturnType
            ) -> ReturnType {
            return requestBlock(self.businessLogic)
        }
    }
    
    @objc(BalanceHeaderPresenterDispatch)
    public class PresenterDispatch: NSObject {
        
        private weak var displayLogic: DisplayLogic?
        
        public init(displayLogic: DisplayLogic) {
            self.displayLogic = displayLogic
        }
        
        public func display(displayBlock: @escaping (_ displayLogic: DisplayLogic) -> Void) {
            guard let displayLogic = self.displayLogic else { return }
            
            DispatchQueue.main.async {
                displayBlock(displayLogic)
            }
        }
        
        public func displaySync(displayBlock: @escaping (_ displayLogic: DisplayLogic) -> Void) {
            guard let displayLogic = self.displayLogic else { return }
            
            displayBlock(displayLogic)
        }
    }
}
