import Foundation

extension DashboardScene {
    
    enum Configurator {
        static func configure(
            viewController: ViewController,
            plugInsProvider: PlugInsProviderProtocol,
            routing: Routing?
            ) {
            
            let interactorQueue: DispatchQueue = DispatchQueue(
                label: "\(NSStringFromClass(InteractorDispatch.self))\(BusinessLogic.self)".queueLabel,
                qos: .userInteractive
            )
            let presenterDispatch = PresenterDispatch(displayLogic: viewController)
            let presenter = Presenter(presenterDispatch: presenterDispatch)
            let interactor = Interactor(
                presenter: presenter,
                queue: interactorQueue,
                plugInsProvider: plugInsProvider
            )
            let interactorDispatch = InteractorDispatch(
                queue: interactorQueue,
                businessLogic: interactor
            )
            viewController.inject(interactorDispatch: interactorDispatch, routing: routing)
        }
    }
}

extension DashboardScene {
    
    class InteractorDispatch {
        
        private let queue: DispatchQueue
        private let businessLogic: BusinessLogic
        
        init(
            queue: DispatchQueue,
            businessLogic: BusinessLogic
            ) {
            
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
