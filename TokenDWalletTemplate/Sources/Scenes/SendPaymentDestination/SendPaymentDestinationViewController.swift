import UIKit

public protocol SendPaymentDestinationDisplayLogic: class {
    typealias Event = SendPaymentDestination.Event
    
    func displayViewDidLoad(viewModel: Event.ViewDidLoad.ViewModel)
    func displaySelectedContact(viewModel: Event.SelectedContact.ViewModel)
    func displayScanRecipientQRAddress(viewModel: Event.ScanRecipientQRAddress.ViewModel)
}

extension SendPaymentDestination {
    public typealias DisplayLogic = SendPaymentDestinationDisplayLogic
    
    @objc(SendPaymentDestinationViewController)
    public class ViewController: UIViewController {
        
        public typealias Event = SendPaymentDestination.Event
        public typealias Model = SendPaymentDestination.Model
        
        // MARK: - Private properties
        
        private let recipientAddressView: RecipientAddressView = RecipientAddressView()
        private var viewConfig: Model.ViewConfig?
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        private var onDeinit: DeinitCompletion = nil
        
        public func inject(
            interactorDispatch: InteractorDispatch?,
            viewConfig: Model.ViewConfig?,
            routing: Routing?,
            onDeinit: DeinitCompletion = nil
            ) {
            
            self.interactorDispatch = interactorDispatch
            self.viewConfig = viewConfig
            self.routing = routing
            self.onDeinit = onDeinit
        }
        
        // MARK: - Overridden
        
        public override func viewDidLoad() {
            super.viewDidLoad()
            
//            let request = Event.ViewDidLoad.Request()
//            self.interactorDispatch?.sendRequest { businessLogic in
//                businessLogic.onViewDidLoad(request: request)
//            }
        }
        
        // MARK: - Private
        
        private func setupRecipientAddressView() {
            if let viewConfig = self.viewConfig {
                self.recipientAddressView.title = viewConfig.recipientAddressFieldTitle
                self.recipientAddressView.placeholder = viewConfig.recipientAddressFieldPlaceholder
            }
            
            self.recipientAddressView.onAddressEdit = { [weak self] (address) in
                let request = Event.EditRecipientAddress.Request(address: address)
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onEditRecipientAddress(request: request)
                })
            }
            
            self.recipientAddressView.onQRAction = { [weak self] in
                self?.routing?.onPresentQRCodeReader({ result in
                    let request = Event.ScanRecipientQRAddress.Request(qrResult: result)
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onScanRecipientQRAddress(request: request)
                    })
                })
            }
            
            self.recipientAddressView.onSelectAccount = { [weak self] in
                self?.routing?.onSelectContactEmail({ [weak self] (email) in
                    let request = Event.SelectedContact.Request(email: email)
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onSelectedContact(request: request)
                    })
                })
            }
        }
    }
}

extension SendPaymentDestination.ViewController: SendPaymentDestination.DisplayLogic {
    public func displayViewDidLoad(viewModel: Event.ViewDidLoad.ViewModel) {
        
    }
    
    public func displaySelectedContact(viewModel: Event.SelectedContact.ViewModel) {
        
    }
    
    public func displayScanRecipientQRAddress(viewModel: Event.ScanRecipientQRAddress.ViewModel) {
        
    }
}
