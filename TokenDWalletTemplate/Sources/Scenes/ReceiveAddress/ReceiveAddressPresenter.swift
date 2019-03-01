import UIKit

protocol ReceiveAddressPresentationLogic {
    func presentViewDidLoadSync(response: ReceiveAddress.Event.ViewDidLoadSync.Response)
    func presentQRCodeRegenerated(response: ReceiveAddress.Event.QRCodeRegenerated.Response)
    func presentValueChanged(response: ReceiveAddress.Event.ValueChanged.Response)
    func presentCopyAction(response: ReceiveAddress.Event.CopyAction.Response)
    func presentShareAction(response: ReceiveAddress.Event.ShareAction.Response)
}

extension ReceiveAddress {
    
    typealias PresentationLogic = ReceiveAddressPresentationLogic
    
    struct Presenter {
        
        private let presenterDispatch: PresenterDispatch
        private let qrCodeGenerator: ReceiveAddressSceneQRCodeGeneratorProtocol
        private let invoiceFormatter: InvoiceFormatterProtocol
        
        init(
            presenterDispatch: PresenterDispatch,
            qrCodeGenerator: ReceiveAddressSceneQRCodeGeneratorProtocol,
            invoiceFormatter: InvoiceFormatterProtocol
            ) {
            
            self.presenterDispatch = presenterDispatch
            self.qrCodeGenerator = qrCodeGenerator
            self.invoiceFormatter = invoiceFormatter
        }
        
        private func availableValueActionsChanged(
            availableActions: [ReceiveAddress.Model.ValueAction]
            ) {
            
            typealias Action = ReceiveAddress.Event.ValueActionsChanged.ViewModel.Action
            
            let availableValueActions = availableActions.map { (action) -> Action in
                let title: String = {
                    switch action {
                    case .copy:
                        return "copy"
                    case .share:
                        return "share"
                    }
                }()
                return Action(
                    title: title,
                    valueAction: action
                )
            }
            let viewModel = ReceiveAddress.Event.ValueActionsChanged.ViewModel(
                availableValueActions: availableValueActions
            )
            
            self.presenterDispatch.display { (displayLogic) in
                displayLogic.displayValueActionsChanged(viewModel: viewModel)
            }
        }
    }
}

extension ReceiveAddress.Presenter: ReceiveAddress.PresentationLogic {
    func presentViewDidLoadSync(response: ReceiveAddress.Event.ViewDidLoadSync.Response) {
        let viewModel = ReceiveAddress.Event.ViewDidLoadSync.ViewModel(
            address: response.address,
            valueLinesNumber: self.invoiceFormatter.estimatedNumberOfLinesInValue
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayViewDidLoadSync(viewModel: viewModel)
        }
    }
    
    func presentValueChanged(response: ReceiveAddress.Event.ValueChanged.Response) {
        self.availableValueActionsChanged(
            availableActions: response.availableValueActions
        )
        
        let viewModel = ReceiveAddress.Event.ValueChanged.ViewModel(value: response.address)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayValueChanged(viewModel: viewModel)
        }
    }
    
    func presentQRCodeRegenerated(response: ReceiveAddress.Event.QRCodeRegenerated.Response) {
        let qrValue = self.invoiceFormatter.qrValueForAddress(
            response.address
        )
        
        self.qrCodeGenerator.generateQRCodeFromString(
            qrValue,
            withTintColor: UIColor.black,
            backgroundColor: UIColor.clear,
            size: response.qrSize
        ) { (code) in
            guard let qrImage = code
                else {
                    return
            }
            
            let viewModel = ReceiveAddress.Event.QRCodeRegenerated.ViewModel(qrCode: qrImage)
            self.presenterDispatch.display { (displayLogic) in
                displayLogic.displayQRCodeRegenerated(viewModel: viewModel)
            }
        }
    }
    
    func presentCopyAction(response: ReceiveAddress.Event.CopyAction.Response) {
        let viewModel = ReceiveAddress.Event.CopyAction.ViewModel(stringToCopy: response.stringToCopy)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayCopyAction(viewModel: viewModel)
        }
    }
    
    func presentShareAction(response: ReceiveAddress.Event.ShareAction.Response) {
        let viewModel = ReceiveAddress.Event.ShareAction.ViewModel(itemsToShare: response.itemsToShare)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayShareAction(viewModel: viewModel)
        }
    }
}
