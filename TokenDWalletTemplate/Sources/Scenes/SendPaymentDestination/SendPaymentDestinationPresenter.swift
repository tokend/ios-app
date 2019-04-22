import Foundation

public protocol SendPaymentDestinationPresentationLogic {
    typealias Event = SendPaymentDestination.Event
    
    func presentViewDidLoad(response: Event.ViewDidLoad.Response)
    func presentSelectedContact(response: Event.SelectedContact.Response)
    func presentScanRecipientQRAddress(response: Event.ScanRecipientQRAddress.Response)
}

extension SendPaymentDestination {
    public typealias PresentationLogic = SendPaymentDestinationPresentationLogic
    
    @objc(SendPaymentDestinationPresenter)
    public class Presenter: NSObject {
        
        public typealias Event = SendPaymentDestination.Event
        public typealias Model = SendPaymentDestination.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        
        // MARK: -
        
        public init(presenterDispatch: PresenterDispatch) {
            self.presenterDispatch = presenterDispatch
        }
    }
}

extension SendPaymentDestination.Presenter: SendPaymentDestination.PresentationLogic {
    public func presentViewDidLoad(response: Event.ViewDidLoad.Response) {
        let viewModel = Event.ViewDidLoad.ViewModel()
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayViewDidLoad(viewModel: viewModel)
        }
    }
    
    public func presentSelectedContact(response: Event.SelectedContact.Response) {
        
    }
    
    public func presentScanRecipientQRAddress(response: Event.ScanRecipientQRAddress.Response) {
        let viewModel: Event.ScanRecipientQRAddress.ViewModel
        
    }
}
