import Foundation
import RxSwift
import TokenDWallet

protocol SendPaymentBusinessLogic {
    
    typealias Event = SendPaymentAmount.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onLoadBalances(request: Event.LoadBalances.Request)
    func onSelectBalance(request: Event.SelectBalance.Request)
    func onBalanceSelected(request: Event.BalanceSelected.Request)
    func onEditAmount(request: Event.EditAmount.Request)
    func onDescriptionUpdated(request: Event.DescriptionUpdated.Request)
    func onSubmitAction(request: Event.SubmitAction.Request)
    func onFeeOverviewAction(request: Event.FeeOverviewAction.Request)
}

extension SendPaymentAmount {
    typealias BusinessLogic = SendPaymentBusinessLogic
    
    class Interactor {
        
        typealias Model = SendPaymentAmount.Model
        typealias Event = SendPaymentAmount.Event
        
        private let presenter: PresentationLogic
        private let queue: DispatchQueue
        private let sceneModel: Model.SceneModel
        private let senderAccountId: String
        private let selectedBalanceId: String?
        private let balanceDetailsLoader: BalanceDetailsLoader
        
        private let feeLoader: FeeLoaderProtocol
        private let feeOverviewer: FeeOverviewerProtocol
        
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
            feeLoader: FeeLoaderProtocol,
            feeOverviewer: FeeOverviewerProtocol
            ) {
            
            self.presenter = presenter
            self.queue = queue
            self.sceneModel = sceneModel
            self.senderAccountId = senderAccountId
            self.selectedBalanceId = selectedBalanceId
            self.balanceDetailsLoader = balanceDetailsLoader
            self.feeLoader = feeLoader
            self.feeOverviewer = feeOverviewer
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
        
        private func updateFeeOverviewAvailability() {
            let available = self.feeOverviewer.checkFeeExistanceFor(
                asset: self.sceneModel.selectedBalance?.asset ?? "",
                feeType: self.sceneModel.feeType
            )
            let response = Event.FeeOverviewAvailability.Response(available: available)
            self.presenter.presentFeeOverviewAvailability(response: response)
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
            
            guard let recipientAddress = self.sceneModel.resolvedRecipientId, recipientAddress.count > 0 else {
                self.presenter.presentPaymentAction(response: .failed(.emptyRecipientAddress))
                return
            }
            
            self.loadFees(
                asset: balance.asset,
                amount: amount,
                accountId: recipientAddress,
                completion: { result in
                    self.presenter.presentPaymentAction(response: .loaded)
                    
                    switch result {
                        
                    case .failed(let error):
                        self.presenter.presentPaymentAction(response: .failed(.failedToLoadFees(error)))
                        
                    case .succeeded(let senderFee, let recipientFee):
                        let sendPaymentModel = Model.SendPaymentModel(
                            senderBalanceId: balance.balanceId,
                            asset: balance.asset,
                            amount: amount,
                            recipientNickname: recipientAddress,
                            recipientAccountId: recipientAddress,
                            senderFee: senderFee,
                            recipientFee: recipientFee,
                            description: self.sceneModel.description ?? "",
                            reference: Date().description
                        )
                        self.presenter.presentPaymentAction(response: .succeeded(sendPaymentModel))
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
            
            self.presenter.presentWithdrawAction(response: .loading)
            
            self.loadWithdrawFees(
                asset: balance.asset,
                amount: amount,
                completion: { [weak self] (result) in
                    switch result {
                        
                    case .failed(let error):
                        self?.presenter.presentWithdrawAction(response: .failed(.failedToLoadFees(error)))
                        
                    case .succeeded(let senderFee):
                        let sendWitdrawtModel = Model.SendWithdrawModel(
                            senderBalance: balance,
                            asset: balance.asset,
                            amount: amount,
                            senderFee: senderFee
                        )
                        self?.presenter.presentWithdrawAction(response: .succeeded(sendWitdrawtModel))
                    }
            })
        }
        
        enum LoadFeesResult {
            case succeeded(senderFee: Model.FeeModel, recipientFee: Model.FeeModel)
            case failed(SendPaymentAmountFeeLoaderResult.FeeLoaderError)
        }
        
        enum LoadWithdrawFeesResult {
            case succeeded(senderFee: Model.FeeModel)
            case failed(SendPaymentAmountFeeLoaderResult.FeeLoaderError)
        }
        
        private func loadFees(
            asset: String,
            amount: Decimal,
            accountId: String,
            completion: @escaping (_ result: LoadFeesResult) -> Void
            ) {
            
            let group = DispatchGroup()
            
            var senderFeeResult: SendPaymentAmountFeeLoaderResult!
            var receiverFeeResult: SendPaymentAmountFeeLoaderResult!
            
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
                
                let feeLoadError: SendPaymentAmountFeeLoaderResult.FeeLoaderError
                
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

extension SendPaymentAmount.Interactor: SendPaymentAmount.BusinessLogic {
    
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
        self.updateFeeOverviewAvailability()
        
        let response = Event.BalanceSelected.Response(
            sceneModel: self.sceneModel,
            amountValid: self.checkAmountValid()
        )
        self.presenter.presentBalanceSelected(response: response)
    }
    
    func onEditAmount(request: Event.EditAmount.Request) {
        self.sceneModel.amount = request.amount
        
        let response = Event.EditAmount.Response(amountValid: self.checkAmountValid())
        self.presenter.presentEditAmount(response: response)
    }
    
    func onDescriptionUpdated(request: Event.DescriptionUpdated.Request) {
        self.sceneModel.description = request.description
    }
    
    func onSubmitAction(request: Event.SubmitAction.Request) {
        switch self.sceneModel.operation {
            
        case .handleSend:
            self.handleSendAction()
            
        case .handleWithdraw:
            self.handleWithdrawSendAction()
        }
    }
    
    func onFeeOverviewAction(request: Event.FeeOverviewAction.Request) {
        guard let asset = self.sceneModel.selectedBalance?.asset else {
            return
        }
        let feeType = self.feeOverviewer.getSystemFeeType(feeType: self.sceneModel.feeType)
        let response = Event.FeeOverviewAction.Response(
            asset: asset,
            feeType: feeType
        )
        self.presenter.presentFeeOverviewAction(response: response)
    }
}
