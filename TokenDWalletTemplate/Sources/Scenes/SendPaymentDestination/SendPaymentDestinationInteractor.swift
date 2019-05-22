import Foundation
import RxSwift
import RxCocoa

public protocol SendPaymentDestinationBusinessLogic {
    typealias Event = SendPaymentDestination.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onEditRecipientAddress(request: Event.EditRecipientAddress.Request)
    func onSelectedContact(request: Event.SelectedContact.Request)
    func onScanRecipientQRAddress(request: Event.ScanRecipientQRAddress.Request)
    func onSubmitAction(request: Event.SubmitAction.Request)
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
        private let contactsFetcher: ContactsFetcherProtocol
        private var sceneModel: Model.SceneModel
        
        private let loadingStatus: BehaviorRelay<Model.LoadingStatus> = BehaviorRelay(value: .loaded)
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            recipientAddressResolver: RecipientAddressResolver,
            contactsFetcher: ContactsFetcherProtocol,
            sceneModel: Model.SceneModel
            ) {
            
            self.presenter = presenter
            self.recipientAddressResolver = recipientAddressResolver
            self.contactsFetcher = contactsFetcher
            self.sceneModel = sceneModel
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
            self.sceneModel.recipientAddress = recipientAddress
            self.presenter.presentScanRecipientQRAddress(response: .succeeded(recipientAddress))
        }
        
        private func handleSelectedContact(email: String) {
            self.recipientAddressResolver.resolve(
                recipientAddress: email,
                completion: { [weak self] (result) in
                    let response: Event.SelectedContact.Response
                    switch result {
                        
                    case .failed(let error):
                        response = .failure(message: error.localizedDescription)
                        
                    case .succeeded(let recipientAddress):
                        self?.sceneModel.recipientAddress = recipientAddress
                        response = .success(recipientAddress)
                    }
                    self?.presenter.presentSelectedContact(response: response)
            })
        }
        
        private func handleSendAction() {
            guard let recipientAddress = self.sceneModel.recipientAddress,
                !recipientAddress.isEmpty else {
                    self.presenter.presentPaymentAction(response: .error(.emptyRecipientAddress))
                    return
            }
            
            self.loadingStatus.accept(.loading)
            self.recipientAddressResolver.resolve(
                recipientAddress: recipientAddress,
                completion: { [weak self] (result) in
                    self?.loadingStatus.accept(.loaded)
                    switch result {
                        
                    case .failed(let error):
                        self?.presenter.presentPaymentAction(response: .error(.failedToResolveRecipientAddress(error)))
                        
                    case .succeeded(let accountId):
                        let destinationModel = Model.SendDestinationModel(
                            recipientNickname: recipientAddress,
                            recipientAccountId: accountId
                        )
                        self?.presenter.presentPaymentAction(response: .destination(destinationModel))
                    }
            })
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
            
            guard let senderFee = self.sceneModel.senderFee else {
                self.presenter.presentWithdrawAction(response: .failed(.failedToFetchFee))
                return
            }
            
            let withdrawModel = Model.SendWithdrawModel(
                senderBalanceId: balance.balanceId,
                asset: balance.asset,
                amount: amount,
                recipientNickname: recipientAddress,
                recipientAddress: recipientAddress,
                senderFee: senderFee
            )
            self.presenter.presentWithdrawAction(response: .succeeded(withdrawModel))
        }
        
        private func fetchContacts() {
            self.contactsFetcher.fetchContacts(completion: { [weak self] (result) in
                let response: Event.ContactsUpdated.Response
                switch result {
                    
                case .failure(let error):
                    response = .error(error.localizedDescription)
                    
                case .success(let cells):
                    if cells.isEmpty {
                        response = .empty
                    } else {
                        let section = Model.SectionModel(
                            title: Localized(.contacts),
                            cells: cells
                        )
                        response = .sections([section])
                    }
                }
                self?.presenter.presentContactsUpdated(response: response)
            })
        }
        
        private func observeLoadingStatus() {
            self.loadingStatus
                .subscribe(onNext: { [weak self] (status) in
                    let response = status
                    self?.presenter.presentLoadingStatusDidChange(response: response)
                })
                .disposed(by: self.disposeBag)
        }
    }
}

extension SendPaymentDestination.Interactor: SendPaymentDestination.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        self.observeLoadingStatus()
        switch self.sceneModel.operation {
            
        case .handleSend:
            self.fetchContacts()
            
        case .handleWithdraw:
            break
        }
    }
    
    public func onEditRecipientAddress(request: Event.EditRecipientAddress.Request) {
        self.sceneModel.recipientAddress = request.address
    }
    
    public func onSelectedContact(request: Event.SelectedContact.Request) {
        self.handleSelectedContact(email: request.email)
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
    
    public func onSubmitAction(request: Event.SubmitAction.Request) {
        switch self.sceneModel.operation {
        case .handleSend:
            self.handleSendAction()
            
        case .handleWithdraw:
            self.handleWithdrawSendAction()
        }
    }
}
