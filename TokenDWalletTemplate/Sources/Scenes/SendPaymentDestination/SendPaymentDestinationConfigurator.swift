import Foundation

extension SendPaymentDestination {
    
    public enum Configurator {
        
        public static func configure(
            viewController: ViewController,
            recipientAddressResolver: RecipientAddressResolver,
            contactsFetcher: ContactsFetcherProtocol,
            sceneModel: SendPaymentDestination.Model.SceneModel,
            viewConfig: Model.ViewConfig?,
            routing: Routing?,
            onDeinit: DeinitCompletion = nil
            ) {
            
            let presenterDispatch = PresenterDispatch(displayLogic: viewController)
            let presenter = Presenter(presenterDispatch: presenterDispatch)
            let interactor = Interactor(
                presenter: presenter,
                recipientAddressResolver: recipientAddressResolver,
                contactsFetcher: contactsFetcher,
                sceneModel: sceneModel
            )
            let interactorDispatch = InteractorDispatch(businessLogic: interactor)
            viewController.inject(
                interactorDispatch: interactorDispatch,
                viewConfig: viewConfig,
                routing: routing,
                onDeinit: onDeinit
            )
        }
    }
}

extension SendPaymentDestination {
    
    @objc(SendPaymentDestinationInteractorDispatch)
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
    
    @objc(SendPaymentDestinationPresenterDispatch)
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
