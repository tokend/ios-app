import Foundation

public protocol SendPaymentDestinationPresentationLogic {
    typealias Event = SendPaymentDestination.Event
    typealias ContactViewModel = SendPaymentDestination.ContactCell.ViewModel
    
    func presentContactsUpdated(response: Event.ContactsUpdated.Response)
    func presentSelectedContact(response: Event.SelectedContact.Response)
    func presentScanRecipientQRAddress(response: Event.ScanRecipientQRAddress.Response)
    func presentPaymentAction(response: Event.PaymentAction.Response)
    func presentWithdrawAction(response: Event.WithdrawAction.Response)
    func presentLoadingStatusDidChange(response: Event.LoadingStatusDidChange.Response)
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
    
    public func presentContactsUpdated(response: Event.ContactsUpdated.Response) {
        let viewModel: Event.ContactsUpdated.ViewModel
        switch response {
            
        case .error(let message):
            viewModel = .error(message)
            
        case .sections(let sections):
            let sectionsViewModels = sections.map { (section) -> Model.SectionViewModel in
                let cells = section.cells.map({ (cell) -> ContactViewModel in
                    return ContactViewModel(name: cell.name, email: cell.email)
                })
                return Model.SectionViewModel(title: section.title, cells: cells)
            }
            viewModel = .sections(sectionsViewModels)
        }
        
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayContactsUpdated(viewModel: viewModel)
        }
    }
    
    public func presentSelectedContact(response: Event.SelectedContact.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySelectedContact(viewModel: viewModel)
        }
    }
    
    public func presentScanRecipientQRAddress(response: Event.ScanRecipientQRAddress.Response) {
        let viewModel: Event.ScanRecipientQRAddress.ViewModel
        switch response {
            
        case .canceled:
            viewModel = .canceled
            
        case .failed(let error):
            viewModel = .failed(errorMessage: error.localizedDescription)
            
        case .succeeded(let address):
            viewModel = .succeeded(address)
        }
        
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayScanRecipientQRAddress(viewModel: viewModel)
        }
    }
    
    public func presentPaymentAction(response: Event.PaymentAction.Response) {
        let viewModel: Event.PaymentAction.ViewModel
        switch response {
            
        case .destination(let model):
            viewModel = .destination(model)
            
        case .error(let error):
            viewModel = .error(error.localizedDescription)
        }
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayPaymentAction(viewModel: viewModel)
        }
    }
    
    public func presentWithdrawAction(response: Event.WithdrawAction.Response) {
        let viewModel: Event.WithdrawAction.ViewModel
        switch response {
            
        case .failed(let error):
            viewModel = .failed(errorMessage: error.localizedDescription)
            
        case .succeeded(let model):
            viewModel = .succeeded(model)
        }
        
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayWithdrawAction(viewModel: viewModel)
        }
    }
    
    public func presentLoadingStatusDidChange(response: Event.LoadingStatusDidChange.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayLoadingStatusDidChange(viewModel: viewModel)
        }
    }
}
