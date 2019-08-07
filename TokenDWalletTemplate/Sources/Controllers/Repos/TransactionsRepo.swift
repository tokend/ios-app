import Foundation
import TokenDSDK
import TokenDWallet
import RxSwift
import RxCocoa

class TransactionsRepo {
    
    // MARK: - Private properties
    
    private let api: TransactionsApi
    private let asset: String
    private let originalAccountId: String
    
    private let operations: BehaviorRelay<[Operation]> = BehaviorRelay(value: [])
    private let loadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
    private let loadingMoreStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
    private var errorStatus: PublishRelay<Swift.Error> = PublishRelay()
    
    private let disposeBag = DisposeBag()
    private let pageSize: Int = 20
    
    private var shouldInitiateLoad: Bool = true
    private var shouldLoadMore: Bool = true
    
    // MARK: - Public properties
    
    public var operationsValue: [Operation] {
        return self.operations.value
    }
    public var loadingStatusValue: LoadingStatus {
        return self.loadingStatus.value
    }
    public var loadingMoreStatusValue: LoadingStatus {
        return self.loadingMoreStatus.value
    }
    
    // MARK: -
    
    init(
        api: TransactionsApi,
        asset: String,
        originalAccountId: String
        ) {
        
        self.api = api
        self.asset = asset
        self.originalAccountId = originalAccountId
        
        self.observeRepoErrorStatus()
    }
    
    // MARK: - Private
    
    private func loadTransactions(
        _ fromLast: Bool,
        completion: @escaping () -> Void
        ) {
        
        let parameters: TransactionsPaymentsRequestParameters = TransactionsPaymentsRequestParameters(
            asset: self.asset,
            cursor: fromLast ? self.operationsValue.last?.pagingToken : nil,
            order: "desc",
            limit: self.pageSize,
            completedOnly: false
        )
        
        self.api.requestPayments(
            accountId: self.originalAccountId,
            parameters: parameters) { [weak self] (result) in
                switch result {
                    
                case .success(let operations):
                    guard let strongSelf = self else {
                        completion()
                        return
                    }
                    
                    let pageSize = self?.pageSize ?? 0
                    self?.shouldLoadMore = operations.count == pageSize
                    if fromLast && operations.isEmpty {
                        completion()
                        return
                    }
                    var newOperations: [Operation] = []
                    if fromLast {
                        newOperations = self?.operationsValue ?? []
                    }
                    
                    let mappedOperations = operations.flatMap({ (baseOperation) -> [Operation] in
                        if let checkSaleState = baseOperation as? CheckSaleStateOperationResponse {
                            let subOperations = checkSaleState.getSubOperations(
                                targetAccountId: strongSelf.originalAccountId,
                                targetAsset: strongSelf.asset
                            )
                            
                            let mapped = subOperations.map({ (subOperation) -> CheckSaleStateOperation in
                                return CheckSaleStateOperation(subOperation: subOperation)
                            })
                            
                            return mapped
                        } else if let manageOffer = baseOperation as? ManageOfferOperationResponse {
                            let subOperations = manageOffer.getSubOperations(
                                targetAccountId: strongSelf.originalAccountId,
                                targetAsset: strongSelf.asset
                            )
                            
                            let mapped = subOperations.map({ (subOperation) -> ManageOfferOperation in
                                return ManageOfferOperation(subOperation: subOperation)
                            })
                            
                            return mapped
                        } else {
                            return [Operation(base: baseOperation)]
                        }
                    })
                    
                    newOperations.append(contentsOf: mappedOperations)
                    self?.operations.accept(newOperations)
                    
                case .failure(let errors):
                    self?.errorStatus.accept(errors)
                }
                
                completion()
        }
    }
    
    private func observeRepoErrorStatus() {
        self.errorStatus
            .asObservable()
            .subscribe(onNext: { [weak self] (_) in
                self?.shouldInitiateLoad = true
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Public
    
    public func reloadTransactions() {
        self.loadingStatus.accept(.loading)
        self.loadTransactions(false, completion: { [weak self] in
            self?.loadingStatus.accept(.loaded)
        })
    }
    
    public func loadMoreTransactions() {
        guard self.shouldLoadMore else {
            self.loadingMoreStatus.accept(.loaded)
            return
        }
        
        self.loadingMoreStatus.accept(.loading)
        self.loadTransactions(true, completion: { [weak self] in
            self?.loadingMoreStatus.accept(.loaded)
        })
    }
    
    public func observeOperations() -> Observable<[Operation]> {
        if self.shouldInitiateLoad {
            self.shouldInitiateLoad = false
            self.reloadTransactions()
        }
        return self.operations.asObservable()
    }
    
    public func observeLoadingStatus() -> Observable<LoadingStatus> {
        return self.loadingStatus.asObservable()
    }
    
    public func observeLoadingMoreStatus() -> Observable<LoadingStatus> {
        return self.loadingMoreStatus.asObservable()
    }
    
    public func observeErrorStatus() -> Observable<Swift.Error> {
        return self.errorStatus.asObservable()
    }
}

extension TransactionsRepo {
    enum LoadingStatus {
        case loading
        case loaded
    }
}
