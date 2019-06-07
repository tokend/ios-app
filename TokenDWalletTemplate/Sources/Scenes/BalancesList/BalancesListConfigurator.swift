import Foundation

extension BalancesList {
    
    public enum Configurator {
        
        static func configure(
            viewController: ViewController,
            sceneModel: Model.SceneModel,
            balancesFetcher: BalancesFetcherProtocol,
            amountFormatter: AmountFormatterProtocol,
            percentFormatter: PercentFormatterProtocol,
            colorsProvider: PieChartColorsProviderProtocol,
            routing: Routing?,
            onDeinit: DeinitCompletion = nil
            ) {
            
            let presenterDispatch = PresenterDispatch(displayLogic: viewController)
            let presenter = Presenter(
                presenterDispatch: presenterDispatch,
                amountFormatter: amountFormatter,
                percentFormatter: percentFormatter,
                colorsProvider: colorsProvider
            )
            let interactor = Interactor(
                presenter: presenter,
                sceneModel: sceneModel,
                balancesFetcher: balancesFetcher
            )
            let interactorDispatch = InteractorDispatch(businessLogic: interactor)
            viewController.inject(
                interactorDispatch: interactorDispatch,
                routing: routing,
                onDeinit: onDeinit
            )
        }
    }
}

extension BalancesList {
    
    @objc(BalancesListInteractorDispatch)
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
    
    @objc(BalancesListPresenterDispatch)
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
