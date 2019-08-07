import Foundation

extension Trade {
    
    enum Configurator {
        static func configure(
            viewController: ViewController,
            assetsFetcher: AssetsFetcherProtocol,
            chartsFetcher: ChartsFetcherProtocol,
            amountFormatter: AmountFormatterProtocol,
            tradeOffersFetcher: OffersFetcherProtocol,
            routing: Routing?
            ) {
            
            let presenterDispatch = PresenterDispatch(displayLogic: viewController)
            let presenter = Presenter(amountFormatter: amountFormatter, presenterDispatch: presenterDispatch)
            let interactor = Interactor(
                presenter: presenter,
                assetsFetcher: assetsFetcher,
                chartsFetcher: chartsFetcher,
                tradeOffersFetcher: tradeOffersFetcher
            )
            let interactorDispatch = InteractorDispatch(businessLogic: interactor)
            viewController.inject(interactorDispatch: interactorDispatch, routing: routing)
        }
    }
}

extension Trade {
    
    class InteractorDispatch {
        
        private let queue: DispatchQueue = DispatchQueue(
            label: [
                "\(NSStringFromClass(InteractorDispatch.self))\(BusinessLogic.self)",
                "queue"
                ].joined(separator: "."),
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
