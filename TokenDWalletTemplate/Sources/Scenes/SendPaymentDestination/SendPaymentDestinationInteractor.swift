import Foundation

public protocol SendPaymentDestinationBusinessLogic {
    typealias Event = SendPaymentDestination.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onEditRecipientAddress(request: Event.EditRecipientAddress.Request)
    func onSelectedContact(request: Event.SelectedContact.Request)
    func onScanRecipientQRAddress(request: Event.ScanRecipientQRAddress.Request)
    
}

extension SendPaymentDestination {
    public typealias BusinessLogic = SendPaymentDestinationBusinessLogic
    
    @objc(SendPaymentDestinationInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = SendPaymentDestination.Event
        public typealias Model = SendPaymentDestination.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private let recipientAddressResolver: RecipientAddressResolver
        private var sceneModel: Model.SceneModel
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            recipientAddressResolver: RecipientAddressResolver
            ) {
            
            self.presenter = presenter
            self.recipientAddressResolver = recipientAddressResolver
            self.sceneModel = Model.SceneModel(
                address: nil,
                accountId: nil
            )
        }
        
        // MARK: - Private
        
        private func handleScanQRCodeValue(_ qrValue: String) {
            self.recipientAddressResolver.resolve(
                recipientAddress: qrValue,
                completion: { [weak self] (result) in
                    let response: Event.ScanRecipientQRAddress.Response
                    switch result {
                        
                    case .failed(let error):
                        
                        switch error {
                            
                        case .invalidAccountIdOrEmail:
                            response = .failed(.invalidAccountId)
                            
                        case .other(let errors):
                            response = .failed(.other(errors))
                        }
                        
                    case .succeeded(let recipientAddress):
                        self?.handleSucceededQRScan(recipientAddress: recipientAddress)
                        return
                    }
                    
                    self?.presenter.presentScanRecipientQRAddress(response: response)
            })
        }
        
        private func handleSucceededQRScan(recipientAddress: String) {
            self.sceneModel.address = recipientAddress
        }
        
        private func handleWithdrawSendAction() {
            guard let balance = self.sceneModel.selectedBalance else {
                self.presenter.presentWithdrawAction(response: .failed(.noBalance))
                return
            }
            
            guard self.sceneModel.amount > 0 else {
                self.presenter.presentWithdrawAction(response: .failed(.emptyAmount))
                return
            }
            
            let amount = self.sceneModel.amount
            guard balance.balance > amount else {
                self.presenter.presentWithdrawAction(response: .failed(.insufficientFunds))
                return
            }
            
            guard let recipientAddress = self.sceneModel.recipientAddress, recipientAddress.count > 0 else {
                self.presenter.presentWithdrawAction(response: .failed(.emptyRecipientAddress))
                return
            }
            
            self.presenter.presentWithdrawAction(response: .loading)
            
            //            self.recipientAddressResolver.resolve(
            //                recipientAddress: recipientAddress,
            //                completion: { [weak self] (result) in
            //                    self?.presenter.presentWithdrawAction(response: .loaded)
            //
            //                    switch result {
            //
            //                    case .failed(let error):
            //                        let response: Event.WithdrawAction.Response = .failed(.failedToResolveRecipientAddress(error))
            //                        self?.presenter.presentWithdrawAction(response: response)
            //
            //                    case .succeeded(let recipientAddress):
            //                        self?.loadWithdrawFees(asset: balance.asset, amount: amount, completion: { (result) in
            //                            switch result {
            //
            //                            case .failed(let error):
            //                                self?.presenter.presentWithdrawAction(response: .failed(.failedToLoadFees(error)))
            //
            //                            case .succeeded(let senderFee):
            //                                let sendWitdrawtModel = Model.SendWithdrawModel(
            //                                    senderBalanceId: balance.balanceId,
            //                                    asset: balance.asset,
            //                                    amount: amount,
            //                                    recipientNickname: recipientAddress,
            //                                    recipientAddress: recipientAddress,
            //                                    senderFee: senderFee
            //                                )
            //
            //                                self?.presenter.presentWithdrawAction(response: .succeeded(sendWitdrawtModel))
            //                            }
            //                        })
            //                    }
            //            })
        }
    }
}

extension SendPaymentDestination.Interactor: SendPaymentDestination.BusinessLogic {
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        let response = Event.ViewDidLoad.Response()
        self.presenter.presentViewDidLoad(response: response)
    }
    
    public func onEditRecipientAddress(request: Event.EditRecipientAddress.Request) {
        self.sceneModel.address = request.address
    }
    
    public func onSelectedContact(request: Event.SelectedContact.Request) {
        self.sceneModel.address = request.email
    }
    
    public func onScanRecipientQRAddress(request: Event.ScanRecipientQRAddress.Request) {
        let response: Event.ScanRecipientQRAddress.Response
        switch request.qrResult {
            
        case .canceled:
            response = .canceled
            
        case .success(let value, _):
            self.handleScanQRCodeValue(value)
            return
        }
        
        self.presenter.presentScanRecipientQRAddress(response: response)
    }
}
