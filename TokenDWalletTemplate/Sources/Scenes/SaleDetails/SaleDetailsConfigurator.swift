import Foundation

extension SaleDetails {
    
    enum Configurator {
        static func configure(
            viewController: ViewController,
            dataProvider: DataProvider,
            amountFormatter: AmountFormatterProtocol,
            dateFormatter: DateFormatterProtocol,
            chartDateFormatter: ChartDateFormatterProtocol,
            investedAmountFormatter: InvestedAmountFormatter,
            feeLoader: FeeLoader,
            cancelInvestWorker: CancelInvestWorkerProtocol,
            investorAccountId: String,
            routing: Routing?
            ) {
            
            let presenterDispatch = PresenterDispatch(displayLogic: viewController)
            let presenter = Presenter(
                presenterDispatch: presenterDispatch,
                amountFormatter: amountFormatter,
                dateFormatter: dateFormatter,
                chartDateFormatter: chartDateFormatter,
                investedAmountFormatter: investedAmountFormatter
            )
            let interactor = Interactor(
                presenter: presenter,
                dataProvider: dataProvider,
                feeLoader: feeLoader,
                cancelInvestWorker: cancelInvestWorker,
                investorAccountId: investorAccountId
            )
            let interactorDispatch = InteractorDispatch(businessLogic: interactor)
            viewController.inject(interactorDispatch: interactorDispatch, routing: routing)
        }
    }
}

extension SaleDetails {
    
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
