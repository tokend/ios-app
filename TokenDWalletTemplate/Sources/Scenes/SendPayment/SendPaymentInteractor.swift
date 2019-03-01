import Foundation
import RxSwift
import TokenDWallet

protocol SendPaymentBusinessLogic {
    
    typealias Event = SendPayment.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onLoadBalances(request: Event.LoadBalances.Request)
    func onSelectBalance(request: Event.SelectBalance.Request)
    func onBalanceSelected(request: Event.BalanceSelected.Request)
    func onEditRecipientAddress(request: Event.EditRecipientAddress.Request)
    func onSelectedContact(request: Event.SelectedContact.Request)
    func onScanRecipientQRAddress(request: Event.ScanRecipientQRAddress.Request)
    func onEditAmount(request: Event.EditAmount.Request)
    func onSubmitAction(request: Event.SubmitAction.Request)
}

extension SendPayment {
    typealias BusinessLogic = SendPaymentBusinessLogic
    
    class Interactor {
        
        typealias Model = SendPayment.Model
        typealias Event = SendPayment.Event
        
        private let presenter: PresentationLogic
        private let queue: DispatchQueue
        private let sceneModel: Model.SceneModel
        private let senderAccountId: String
        private let selectedBalanceId: String?
        private let balanceDetailsLoader: BalanceDetailsLoader
        private let recipientAddressResolver: RecipientAddressResolver
        
        private let feeLoader: FeeLoaderProtocol
        
        private var balances: [Model.BalanceDetails] = []
        private var shouldLoadBalances: Bool = true
        
        private let disposeBag = DisposeBag()
        
        init(
            presenter: PresentationLogic,
            queue: DispatchQueue,
            sceneModel: Model.SceneModel,
            senderAccountId: String,
            selectedBalanceId: String?,
            balanceDetailsLoader: BalanceDetailsLoader,
            recipientAddressResolver: RecipientAddressResolver,
            feeLoader: FeeLoaderProtocol
            ) {
            self.presenter = presenter
            self.queue = queue
            self.sceneModel = sceneModel
            self.senderAccountId = senderAccountId
            self.selectedBalanceId = selectedBalanceId
            self.balanceDetailsLoader = balanceDetailsLoader
            self.recipientAddressResolver = recipientAddressResolver
            self.feeLoader = feeLoader
        }
        
        // MARK: - Private
        
        private func setBalanceSelected(_ balanceId: String) {
            guard let balance = self.balances.first(where: { (balance) in
                return balance.balanceId == balanceId
            }) else {
                return
            }
            
            self.sceneModel.selectedBalance = balance
        }
        
        private func selectFirstBalance() {
            guard let balance = self.balances.first else {
                return
            }
            
            self.sceneModel.selectedBalance = balance
        }
        
        private func getBalanceWith(balanceId: String) -> Model.BalanceDetails? {
            return self.balances.first(where: { (balanceDetails) in
                return balanceDetails.balanceId == balanceId
            })
        }
        
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
            self.sceneModel.resolvedRecipientId = recipientAddress
            let response = Event.ScanRecipientQRAddress.Response.succeeded(
                sceneModel: self.sceneModel,
                amountValid: self.checkAmountValid()
            )
            self.presenter.presentScanRecipientQRAddress(response: response)
        }
        
        private func checkAmountValid() -> Bool {
            guard let balance = self.sceneModel.selectedBalance else {
                return true
            }
            
            let amount = self.sceneModel.amount
            let isValid = amount <= balance.balance
            
            return isValid
        }
        
        private func observeLoadingStatus() {
            self.balanceDetailsLoader
                .observeLoadingStatus()
                .subscribe(onNext: { [weak self] (status) in
                    self?.presenter.presentLoadBalances(response: status.responseValue)
                })
                .disposed(by: self.disposeBag)
        }
        private func observeErrorStatus() {
            self.balanceDetailsLoader
                .observeErrors()
                .subscribe(onNext: { [weak self] (error) in
                    self?.presenter.presentLoadBalances(response: .failed(error))
                })
                .disposed(by: self.disposeBag)
        }
        
        // MARK: - Send
        
        private func handleSendAction() {
            guard let balance = self.sceneModel.selectedBalance else {
                self.presenter.presentPaymentAction(response: .failed(.noBalance))
                return
            }
            
            guard self.sceneModel.amount > 0 else {
                self.presenter.presentPaymentAction(response: .failed(.emptyAmount))
                return
            }
            
            let amount = self.sceneModel.amount
            guard balance.balance > amount else {
                self.presenter.presentPaymentAction(response: .failed(.insufficientFunds))
                return
            }
            
            guard let recipientAddress = self.sceneModel.recipientAddress, recipientAddress.count > 0 else {
                self.presenter.presentPaymentAction(response: .failed(.emptyRecipientAddress))
                return
            }
            
            self.presenter.presentPaymentAction(response: .loading)
            
            self.recipientAddressResolver.resolve(
                recipientAddress: recipientAddress,
                completion: { [weak self] (result) in
                    switch result {
                        
                    case .failed(let error):
                        self?.presenter.presentPaymentAction(response: .loaded)
                        self?.presenter.presentPaymentAction(response: .failed(.failedToResolveRecipientAddress(error)))
                        
                    case .succeeded(let accountId):
                        self?.loadFees(
                            asset: balance.asset,
                            amount: amount,
                            accountId: accountId,
                            completion: { result in
                                self?.presenter.presentPaymentAction(response: .loaded)
                                
                                switch result {
                                    
                                case .failed(let error):
                                    self?.presenter.presentPaymentAction(response: .failed(.failedToLoadFees(error)))
                                    
                                case .succeeded(let senderFee, let recipientFee):
                                    let sendPaymentModel = Model.SendPaymentModel(
                                        senderBalanceId: balance.balanceId,
                                        asset: balance.asset,
                                        amount: amount,
                                        recipientNickname: recipientAddress,
                                        recipientAccountId: accountId,
                                        senderFee: senderFee,
                                        recipientFee: recipientFee,
                                        reference: Date().description
                                    )
                                    self?.presenter.presentPaymentAction(response: .succeeded(sendPaymentModel))
                                }
                        })
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
            
            self.presenter.presentWithdrawAction(response: .loading)
            
            self.recipientAddressResolver.resolve(
                recipientAddress: recipientAddress,
                completion: { [weak self] (result) in
                    self?.presenter.presentWithdrawAction(response: .loaded)
                    
                    switch result {
                        
                    case .failed(let error):
                        let response: Event.WithdrawAction.Response = .failed(.failedToResolveRecipientAddress(error))
                        self?.presenter.presentWithdrawAction(response: response)
                        
                    case .succeeded(let recipientAddress):
                        self?.loadWithdrawFees(asset: balance.asset, amount: amount, completion: { (result) in
                            switch result {
                                
                            case .failed(let error):
                                self?.presenter.presentWithdrawAction(response: .failed(.failedToLoadFees(error)))
                                
                            case .succeeded(let senderFee):
                                let sendWitdrawtModel = Model.SendWithdrawModel(
                                    senderBalanceId: balance.balanceId,
                                    asset: balance.asset,
                                    amount: amount,
                                    recipientNickname: recipientAddress,
                                    recipientAddress: recipientAddress,
                                    senderFee: senderFee
                                )
                                
                                self?.presenter.presentWithdrawAction(response: .succeeded(sendWitdrawtModel))
                            }
                        })
                    }
            })
        }
        
        enum LoadFeesResult {
            case succeeded(senderFee: Model.FeeModel, recipientFee: Model.FeeModel)
            case failed(SendPaymentFeeLoaderResult.FeeLoaderError)
        }
        
        enum LoadWithdrawFeesResult {
            case succeeded(senderFee: Model.FeeModel)
            case failed(SendPaymentFeeLoaderResult.FeeLoaderError)
        }
        
        private func loadFees(
            asset: String,
            amount: Decimal,
            accountId: String,
            completion: @escaping (_ result: LoadFeesResult) -> Void
            ) {
            
            let group = DispatchGroup()
            
            var senderFeeResult: SendPaymentFeeLoaderResult!
            var receiverFeeResult: SendPaymentFeeLoaderResult!
            
            group.enter()
            self.feeLoader.loadFee(
                accountId: self.senderAccountId,
                asset: asset,
                feeType: self.sceneModel.feeType,
                amount: amount,
                subtype: TokenDWallet.PaymentFeeType.outgoing.rawValue,
                completion: { (result) in
                    senderFeeResult = result
                    group.leave()
            })
            
            group.enter()
            self.feeLoader.loadFee(
                accountId: accountId,
                asset: asset,
                feeType: self.sceneModel.feeType,
                amount: amount,
                subtype: TokenDWallet.PaymentFeeType.incoming.rawValue,
                completion: { (result) in
                    receiverFeeResult = result
                    group.leave()
            })
            
            group.notify(queue: self.queue, execute: {
                
                let feeLoadError: SendPaymentFeeLoaderResult.FeeLoaderError
                
                switch (senderFeeResult!, receiverFeeResult!) {
                    
                case (.succeeded(let senderFee), .succeeded(let receiverFee)):
                    completion(.succeeded(senderFee: senderFee, recipientFee: receiverFee))
                    return
                    
                case (.failed(let error), .succeeded):
                    feeLoadError = error
                case (.succeeded, .failed(let error)):
                    feeLoadError = error
                case (.failed(let error), .failed):
                    feeLoadError = error
                }
                
                completion(.failed(feeLoadError))
            })
        }
        
        private func loadWithdrawFees(
            asset: String,
            amount: Decimal,
            completion: @escaping (_ result: LoadWithdrawFeesResult) -> Void
            ) {
            
            self.feeLoader.loadFee(
                accountId: self.senderAccountId,
                asset: asset,
                feeType: self.sceneModel.feeType,
                amount: amount,
                subtype: 0,
                completion: { (result) in
                    
                    switch result {
                    case .succeeded(let senderFee):
                        completion(.succeeded(senderFee: senderFee))
                        
                    case .failed(let error):
                        completion(.failed(error))
                    }
            })
        }
    }
}

// MARK: - BusinessLogic

extension SendPayment.Interactor: SendPayment.BusinessLogic {
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        let response = Event.ViewDidLoad.Response(
            sceneModel: self.sceneModel,
            amountValid: self.checkAmountValid()
        )
        self.presenter.presentViewDidLoad(response: response)
    }
    
    func onLoadBalances(request: Event.LoadBalances.Request) {
        guard self.shouldLoadBalances else { return }
        
        self.balanceDetailsLoader
            .observeBalanceDetails()
            .subscribe(
                onNext: { [weak self] (balanceDetails) in
                    guard let strongSelf = self else { return }
                    
                    self?.balances = balanceDetails
                    if let balanceId = self?.selectedBalanceId {
                        self?.setBalanceSelected(balanceId)
                    } else {
                        self?.selectFirstBalance()
                    }
                    
                    self?.presenter.presentLoadBalances(response: .succeeded(
                        sceneModel: strongSelf.sceneModel,
                        amountValid: self?.checkAmountValid() ?? false
                        )
                    )
            })
            .disposed(by: self.disposeBag)
        self.observeLoadingStatus()
        self.observeErrorStatus()
        self.balanceDetailsLoader.loadBalanceDetails()
        self.shouldLoadBalances = false
    }
    
    func onSelectBalance(request: Event.SelectBalance.Request) {
        let response = Event.SelectBalance.Response(balances: self.balances)
        self.presenter.presentSelectBalance(response: response)
    }
    
    func onBalanceSelected(request: Event.BalanceSelected.Request) {
        guard let balance = self.getBalanceWith(balanceId: request.balanceId) else { return }
        
        self.sceneModel.selectedBalance = balance
        let response = Event.BalanceSelected.Response(
            sceneModel: self.sceneModel,
            amountValid: self.checkAmountValid()
        )
        self.presenter.presentBalanceSelected(response: response)
    }
    
    func onEditRecipientAddress(request: Event.EditRecipientAddress.Request) {
        self.sceneModel.recipientAddress = request.address
    }
    
    func onSelectedContact(request: Event.SelectedContact.Request) {
        self.sceneModel.recipientAddress = request.email
        
        let response = Event.SelectedContact.Response(
            sceneModel: self.sceneModel,
            amountValid: self.checkAmountValid()
        )
        self.presenter.presentSelectedContact(response: response)
    }
    
    func onScanRecipientQRAddress(request: Event.ScanRecipientQRAddress.Request) {
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
    
    func onEditAmount(request: Event.EditAmount.Request) {
        self.sceneModel.amount = request.amount
        
        let response = Event.EditAmount.Response(amountValid: self.checkAmountValid())
        self.presenter.presentEditAmount(response: response)
    }
    
    func onSubmitAction(request: Event.SubmitAction.Request) {
        switch self.sceneModel.operation {
        case .handleSend:
            self.handleSendAction()
        case .handleWithdraw:
            self.handleWithdrawSendAction()
        }
    }
}
