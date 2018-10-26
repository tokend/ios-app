import Foundation
import RxCocoa
import RxSwift
import TokenDSDK

extension TransactionsListScene {
    class PaymentsFetcher: TransactionsFetcherProtocol {
        
        // MARK: - Private properties
        
        private let transactionsBehaviorRelay: BehaviorRelay<Transactions> = BehaviorRelay(value: [])
        private let loadingStatusBehaviorRelay: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
        private let loadingMoreStatusBehaviorRelay: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
        private let errorStatus: PublishRelay<Swift.Error> = PublishRelay()
        
        private var trRepoTransactionsDisposable: Disposable?
        private var trRepoLoadingStatusDisposable: Disposable?
        private var trRepoLoadingMoreStatusDisposable: Disposable?
        private var balancesRepoLoadingStatusDisposable: Disposable?
        private let disposeBag: DisposeBag = DisposeBag()
        
        private let reposController: ReposController
        private let rateProvider: RateProviderProtocol
        private let rateAsset: String = "USD"
        
        private var asset: String?
        private let originalAccountId: String
        private var balancesIds: [String] {
            return self.reposController.balancesRepo.balancesDetailsValue.compactMap({ (balance) -> String? in
                switch balance {
                case .created(let details):
                    return details.balanceId
                case .creating:
                    return nil
                }
            })
        }
        
        // MARK: - Public properties
        
        var transactions: TransactionsListSceneTransactionsFetcherProtocol.Transactions {
            return self.transactionsBehaviorRelay.value
        }
        
        var loadingStatus: TransactionsListSceneTransactionsFetcherProtocol.LoadingStatus {
            return self.loadingStatusBehaviorRelay.value
        }
        
        var loadingMoreStatus: TransactionsListSceneTransactionsFetcherProtocol.LoadingStatus {
            return self.loadingMoreStatusBehaviorRelay.value
        }
        
        // MARK: -
        
        init(
            reposController: ReposController,
            rateProvider: RateProviderProtocol,
            originalAccountId: String
            ) {
            
            self.reposController = reposController
            self.rateProvider = rateProvider
            self.originalAccountId = originalAccountId
            
            self.observeRateChanges()
            self.observeBalancesDetails()
            self.observeBalancesRepoLoadingStatus()
            self.observeBalancesRepoErrorStatus()
        }
        
        // MARK: - Public
        
        func setAsset(_ asset: String) {
            guard self.asset != asset else {
                return
            }
            self.asset = asset
            
            self.observeRepoLoadingStatus()
            self.observeRepoLoadingMoreStatus()
            self.observeRepoErrorStatus()
            self.observeRepoTransactions()
            self.observeBalancesRepoLoadingStatus()
        }
        
        func observeTransactions() -> Observable<TransactionsListSceneTransactionsFetcherProtocol.Transactions> {
            return self.transactionsBehaviorRelay.asObservable()
        }
        
        func observeLoadingStatus() -> Observable<TransactionsListSceneTransactionsFetcherProtocol.LoadingStatus> {
            return self.loadingStatusBehaviorRelay.asObservable()
        }
        
        func observeLoadingMoreStatus() -> Observable<TransactionsListSceneTransactionsFetcherProtocol.LoadingStatus> {
            return self.loadingMoreStatusBehaviorRelay.asObservable()
        }
        
        func observeErrorStatus() -> Observable<Error> {
            return self.errorStatus.asObservable()
        }
        
        func loadMoreTransactions() {
            self.transactionsRepo()?.loadMoreTransactions()
        }
        
        func reloadTransactions() {
            self.transactionsRepo()?.reloadTransactions()
            self.reloadBalancesDetails()
        }
        
        // MARK: - Private
        
        private func reloadBalancesDetails() {
            self.reposController.balancesRepo.reloadBalancesDetails()
        }
        
        private func observeRepoLoadingStatus() {
            self.trRepoLoadingStatusDisposable?.dispose()
            let disposable = self.transactionsRepo()?
                .observeLoadingStatus()
                .subscribe(onNext: { [weak self] (status) in
                    self?.loadingStatusBehaviorRelay.accept(status.status)
                })
            self.trRepoLoadingStatusDisposable = disposable
            disposable?.disposed(by: self.disposeBag)
        }
        
        private func observeRepoLoadingMoreStatus() {
            self.trRepoLoadingMoreStatusDisposable?.dispose()
            let disposable = self.transactionsRepo()?
                .observeLoadingMoreStatus()
                .subscribe(onNext: { [weak self] (status) in
                    self?.loadingMoreStatusBehaviorRelay.accept(status.status)
                })
            self.trRepoLoadingMoreStatusDisposable = disposable
            disposable?.disposed(by: self.disposeBag)
        }
        
        private func observeRepoTransactions() {
            self.trRepoTransactionsDisposable?.dispose()
            let disposable = self.transactionsRepo()?
                .observeOperations()
                .subscribe(onNext: { [weak self] (_) in
                    self?.transactionsDidChange()
                })
            self.trRepoTransactionsDisposable = disposable
            disposable?.disposed(by: self.disposeBag)
        }
        
        private func observeRepoErrorStatus() {
            self.transactionsRepo()?
                .observeErrorStatus()
                .subscribe(onNext: { [weak self] (error) in
                    self?.errorStatus.accept(error)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeBalancesDetails() {
            self.reposController
                .balancesRepo
                .observeBalancesDetails()
                .subscribe(onNext: { [weak self] (_) in
                    self?.transactionsDidChange()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeBalancesRepoLoadingStatus() {
            self.balancesRepoLoadingStatusDisposable?.dispose()
            let disposable = self.reposController.balancesRepo
                .observeLoadingStatus()
                .subscribe(onNext: { [weak self] (status) in
                    self?.loadingStatusBehaviorRelay.accept(status.status)
                })
            self.balancesRepoLoadingStatusDisposable = disposable
            disposable.disposed(by: self.disposeBag)
        }
        
        private func observeBalancesRepoErrorStatus() {
            self.reposController.balancesRepo
                .observeErrorStatus()
                .subscribe(onNext: { [weak self] (error) in
                    self?.errorStatus.accept(error)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeRateChanges() {
            self.rateProvider
                .rate
                .subscribe(onNext: { [weak self] (_) in
                    self?.transactionsDidChange()
                })
                .disposed(by: self.disposeBag)
        }
        
        // MARK: Helpers
        
        private func transactionsDidChange() {
            let transactions = self.transactionsRepo()?.operationsValue ?? []
            let parsedTransactions = self.parseTransactions(transactions)
            self.transactionsBehaviorRelay.accept(parsedTransactions)
        }
        
        private func parseTransactions(_ transactions: [TransactionsRepo.Operation]) -> Transactions {
            let transactions = transactions.compactMap { (operation) -> Transaction? in
                return self.parseTransactionsFromOperation(operation)
            }
            return transactions
        }
        
        private func parseTransactionsFromOperation(_ operation: TransactionsRepo.Operation) -> Transaction? {
            // swiftlint:disable statement_position
            if let payment = operation.base as? PaymentOperationResponse {
                return self.parsePayment(payment, accountId: self.originalAccountId, operation: operation)
            }
                
            else if let paymentv2 = operation.base as? PaymentV2OperationResponse {
                return self.parsePaymentV2(paymentv2, accountId: self.originalAccountId, operation: operation)
            }
                
            else if let withdraw = operation.base as? CreateWithdrawalRequest {
                return self.parseWithdraw(withdraw, asset: self.asset ?? "", operation: operation)
            }
                
            else if let checkSaleState = operation as? TransactionsRepo.CheckSaleStateOperation {
                return self.parseCheckSaleState(checkSaleState, operation: operation)
            }
                
            else if let manageOffer = operation as? TransactionsRepo.ManageOfferOperation {
                return self.parseManageOffer(manageOffer, operation: operation)
            }
                
            else if let createIssuance = operation.base as? CreateIssuanceRequestResponse {
                return self.parseCreateIssuance(createIssuance, operation: operation)
            }
                
            else {
                return nil
            }
            // swiftlint:enable statement_position
        }
        
        private func parsePayment(
            _ payment: PaymentOperationResponse,
            accountId: String,
            operation: TransactionsRepo.Operation
            ) -> Transaction {
            
            let wasSent: Bool = payment.fromAccountId == accountId
            let amountValue: Decimal = payment.amount
            let assetValue: String = payment.asset
            let amount = Amount(
                value: wasSent ? -amountValue : amountValue,
                asset: assetValue
            )
            let amountType: Transaction.AmountType = wasSent ? .negative : .positive
            let counterparty: String? = wasSent ? payment.toAccountId : payment.fromAccountId
            let rate: Amount? = {
                guard let rate = self.rateProvider.rateForAmount(
                    amountValue,
                    ofAsset: assetValue,
                    destinationAsset: self.rateAsset
                    ) else {
                        return nil
                }
                return Amount(
                    value: rate,
                    asset: self.rateAsset
                )
            }()
            let transactionType = self.getTransactionType(operation, isIncome: !wasSent)
            let operation = Transaction(
                identifier: payment.id,
                type: transactionType,
                amount: amount,
                amountType: amountType,
                counterparty: counterparty,
                rate: rate,
                date: payment.ledgerCloseTime
            )
            return operation
        }
        
        private func parsePaymentV2(
            _ payment: PaymentV2OperationResponse,
            accountId: String,
            operation: TransactionsRepo.Operation
            ) -> Transaction {
            
            let wasSent: Bool = payment.fromAccountId == accountId
            let amountValue = payment.amount
            let assetValue = payment.asset
            let amount = Amount(
                value: wasSent ? -amountValue : amountValue,
                asset: assetValue
            )
            let amountType: Transaction.AmountType = wasSent ? .negative : .positive
            let counterparty: String? = wasSent ? payment.toAccountId : payment.fromAccountId
            let rate: Amount? = {
                guard let rate = self.rateProvider.rateForAmount(
                    amountValue,
                    ofAsset: assetValue,
                    destinationAsset: self.rateAsset
                    ) else {
                        return nil
                }
                return Amount(
                    value: rate,
                    asset: self.rateAsset
                )
            }()
            
            let transactionType = self.getTransactionType(operation, isIncome: !wasSent)
            let operation = Transaction(
                identifier: payment.id,
                type: transactionType,
                amount: amount,
                amountType: amountType,
                counterparty: counterparty,
                rate: rate,
                date: payment.ledgerCloseTime
            )
            return operation
        }
        
        private func parseWithdraw(
            _ withdraw: CreateWithdrawalRequest,
            asset: String,
            operation: TransactionsRepo.Operation
            ) -> Transaction {
            
            let amountValue = withdraw.amount
            let amount = Amount(
                value: -amountValue,
                asset: withdraw.destAsset
            )
            let rate: Amount? = {
                guard let rate = self.rateProvider.rateForAmount(
                    amountValue,
                    ofAsset: asset,
                    destinationAsset: self.rateAsset
                    ) else {
                        return nil
                }
                return Amount(
                    value: rate,
                    asset: self.rateAsset
                )
            }()
            let transactionType = self.getTransactionType(operation, isIncome: false)
            let operation = Transaction(
                identifier: withdraw.id,
                type: transactionType,
                amount: amount,
                amountType: withdraw.stateValue == .success ? .negative : .neutral,
                counterparty: withdraw.externalDetails?.address,
                rate: rate,
                date: withdraw.ledgerCloseTime
            )
            return operation
        }
        
        private func parseCreateIssuance(
            _ issuance: CreateIssuanceRequestResponse,
            operation: TransactionsRepo.Operation
            ) -> Transaction {
            
            let amountValue = issuance.amount
            let assetValue = issuance.asset
            let amount = Amount(
                value: amountValue,
                asset: assetValue
            )
            let rate: Amount? = {
                guard let rate = self.rateProvider.rateForAmount(
                    amountValue,
                    ofAsset: assetValue,
                    destinationAsset: self.rateAsset
                    ) else {
                        return nil
                }
                return Amount(
                    value: rate,
                    asset: self.rateAsset
                )
            }()
            
            let transactionType = self.getTransactionType(operation, isIncome: true)
            let operation = Transaction(
                identifier: issuance.id,
                type: transactionType,
                amount: amount,
                amountType: .positive,
                counterparty: nil,
                rate: rate,
                date: issuance.ledgerCloseTime
            )
            return operation
        }
        
        private func parseCheckSaleState(
            _ checkSaleState: TransactionsRepo.CheckSaleStateOperation,
            operation: TransactionsRepo.Operation
            ) -> Transaction {
            
            let amount = Amount(
                value: checkSaleState.amount,
                asset: checkSaleState.asset
            )
            let amountType: Transaction.AmountType = checkSaleState.match.isBuy ? .positive : .negative
            let rate = Amount(
                value: checkSaleState.match.price,
                asset: checkSaleState.match.quoteAsset
            )
            let transactionType = self.getTransactionType(operation, isIncome: checkSaleState.match.isBuy)
            let transaction = Transaction(
                identifier: checkSaleState.id,
                type: transactionType,
                amount: amount,
                amountType: amountType,
                counterparty: nil,
                rate: rate,
                date: checkSaleState.ledgerCloseTime
            )
            
            return transaction
        }
        
        private func parseManageOffer(
            _ manageOffer: TransactionsRepo.ManageOfferOperation,
            operation: TransactionsRepo.Operation
            ) -> Transaction {
            
            return self.parseCheckSaleState(manageOffer, operation: operation)
        }
        
        private func getTransactionType(
            _ operation: TransactionsRepo.Operation,
            isIncome: Bool
            ) -> Transaction.TransactionType {
            
            switch operation.typeValue {
                
            case .checkSaleState:
                return .checkSaleState(income: isIncome)
                
            case .createIssuanceRequest:
                return .createIssuance
                
            case .createWithdrawalRequest:
                return .createWithdrawal
                
            case .manageOffer:
                return .manageOffer(sold: isIncome)
                
            case .payment, .paymentv2, .unknown:
                return .payment(sent: !isIncome)
            }
        }
        
        private func transactionsRepo() -> TransactionsRepo? {
            guard let asset = self.asset else {
                return nil
            }
            
            return self.reposController.transactionsRepoForAsset(asset)
        }
    }
}

private extension TransactionsRepo.LoadingStatus {
    var status: TransactionsListSceneTransactionsFetcherProtocol.LoadingStatus {
        switch self {
        case .loading:
            return .loading
        case .loaded:
            return .loaded
        }
    }
}

private extension BalancesRepo.LoadingStatus {
    var status: TransactionsListSceneTransactionsFetcherProtocol.LoadingStatus {
        switch self {
        case .loading:
            return .loading
        case .loaded:
            return .loaded
        }
    }
}

private typealias Transaction = TransactionsListScene.Model.Transaction
private typealias Amount = TransactionsListScene.Model.Amount
