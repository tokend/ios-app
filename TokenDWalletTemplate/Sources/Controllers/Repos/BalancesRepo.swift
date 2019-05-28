import Foundation
import TokenDSDK
import TokenDWallet
import DLCryptoKit
import RxCocoa
import RxSwift

public class BalancesRepo {
    
    public typealias Asset = String
    public typealias BalanceDetails = TokenDSDK.BalanceDetails
    
    // MARK: - Private properties
    
    private let api: TokenDSDK.BalancesApi
    private let transactionSender: TransactionSender
    private let originalAccountId: String
    private let accountId: AccountID
    private let walletId: String
    private let networkInfoFetcher: NetworkInfoFetcher
    
    private let disposeBag = DisposeBag()
    
    private var shouldInitiateLoad: Bool = true
    
    private let balancesDetails: BehaviorRelay<[BalanceState]> = BehaviorRelay(value: [])
    private var loadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay<LoadingStatus>(value: .loaded)
    private let errorStatus: PublishRelay<Swift.Error> = PublishRelay()
    
    // MARK: - Public properties
    
    public var balancesDetailsValue: [BalanceState] {
        return self.balancesDetails.value
    }
    
    public var loadingStatusValue: LoadingStatus {
        return self.loadingStatus.value
    }
    
    // MARK: -
    
    public init(
        api: TokenDSDK.BalancesApi,
        transactionSender: TransactionSender,
        originalAccountId: String,
        accountId: AccountID,
        walletId: String,
        networkInfoFetcher: NetworkInfoFetcher
        ) {
        
        self.api = api
        self.transactionSender = transactionSender
        self.originalAccountId = originalAccountId
        self.accountId = accountId
        self.walletId = walletId
        self.networkInfoFetcher = networkInfoFetcher
        
        self.observeRepoErrorStatus()
        self.observeTransactionActions()
    }
    
    // MARK: - Private
    
    private enum ReloadBalanceDetailsResult {
        case succeeded(balances: [BalanceState])
        case failed(ApiErrors)
    }
    private func reloadBalancesDetails(
        _ completion: ((ReloadBalanceDetailsResult) -> Void)? = nil
        ) {
        
        self.loadingStatus.accept(.loading)
        self.api.requestDetails(
            accountId: self.originalAccountId,
            completion: { [weak self] (result) in
                self?.loadingStatus.accept(.loaded)
                switch result {
                    
                case .success(let balances):
                    let balancesDetails = balances.map({ (details) -> BalanceState in
                        return .created(details)
                    })
                    completion?(.succeeded(balances: balancesDetails))
                    
                case .failure(let errors):
                    completion?(.failed(errors))
                }
        })
    }
    
    private func observeRepoErrorStatus() {
        self.errorStatus
            .asObservable()
            .subscribe(onNext: { [weak self] (_) in
                self?.shouldInitiateLoad = true
            })
            .disposed(by: self.disposeBag)
    }
    
    private func observeTransactionActions() {
        self.transactionSender
            .observeTransactionActions()
            .do(onNext: { [weak self] in
                self?.reloadBalancesDetails()
            })
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Public
    
    func observeBalancesDetails() -> Observable<[BalanceState]> {
        if self.shouldInitiateLoad {
            self.shouldInitiateLoad = false
            self.reloadBalancesDetails()
        }
        return self.balancesDetails.asObservable()
    }
    
    func observeLoadingStatus() -> Observable<LoadingStatus> {
        return loadingStatus.asObservable()
    }
    
    func observeErrorStatus() -> Observable<Swift.Error> {
        return self.errorStatus.asObservable()
    }
    
    func reloadBalancesDetails() {
        self.loadingStatus.accept(.loading)
        self.reloadBalancesDetails { [weak self] (result) in
            self?.loadingStatus.accept(.loaded)
            switch result {
            case .failed(let errors):
                self?.errorStatus.accept(errors)
            case .succeeded(let balances):
                self?.saveBalancesDetails(balances)
            }
        }
    }
    
    enum CreateBalanceResult {
        case succeeded
        case failed(Swift.Error)
    }
    func createBalanceForAsset(
        _ asset: Asset,
        completion: @escaping (CreateBalanceResult) -> Void
        ) {
        
        var new = self.balancesDetailsValue
        
        let existing = new.first(where: { (state) -> Bool in
            return state.asset == asset
        })
        if existing != nil {
            return
        }
        
        new.append(.creating(asset))
        self.balancesDetails.accept(new)
        
        self.networkInfoFetcher.fetchNetworkInfo({ [weak self] (result) in
            switch result {
                
            case .failed(let error):
                completion(.failed(error))
                
            case .succeeded(let networkInfo):
                self?.createBalance(
                    asset: asset,
                    networkInfo: networkInfo,
                    completion: completion
                )
            }
        })
    }
    
    private func createBalance(
        asset: String,
        networkInfo: NetworkInfoModel,
        completion: @escaping (CreateBalanceResult) -> Void
        ) {
        
        let createBalanceOperation = ManageBalanceOp(
            action: ManageBalanceAction.create,
            destination: self.accountId,
            asset: asset,
            ext: .emptyVersion()
        )
        
        let transactionBuilder: TransactionBuilder = TransactionBuilder(
            networkParams: networkInfo.networkParams,
            sourceAccountId: self.accountId,
            params: networkInfo.getTxBuilderParams(sendDate: Date())
        )
        
        transactionBuilder.add(
            operationBody: .manageBalance(createBalanceOperation),
            operationSourceAccount: self.accountId
        )
        
        do {
            let transaction = try transactionBuilder.buildTransaction()
            
            try self.transactionSender.sendTransaction(
                transaction,
                walletId: self.walletId,
                completion: { [weak self] (result) in
                    switch result {
                        
                    case .succeeded:
                        self?.reloadBalancesDetails({ [weak self] (result) in
                            self?.removeBalanceDetailsWithAsset(asset)
                            switch result {
                            case .failed:
                                break
                            case .succeeded(let balances):
                                self?.saveBalancesDetails(balances)
                            }
                            completion(.succeeded)
                        })
                        
                    case .failed(let error):
                        completion(.failed(error))
                    }
            })
        } catch let error {
            completion(.failed(error))
        }
    }
}

// MARK: - Edit sequence methods

extension BalancesRepo {
    
    private func saveBalancesDetails(_ details: [BalanceState]) {
        var newDetails = self.balancesDetailsValue.filter { (state) -> Bool in
            switch state {
            case .creating:
                return true
            case .created:
                return false
            }
        }
        
        for detail in details {
            newDetails = self.appendingElement(detail, to: newDetails)
        }
        
        self.balancesDetails.accept(newDetails)
    }
    
    private func writeBalanceDetails(
        _ details: BalanceState
        ) {
        
        self.balancesDetails.accept(self.appendingElement(
            details,
            to: self.balancesDetailsValue
        ))
    }
    
    private func removeBalanceDetailsWithAsset(
        _ asset: Asset
        ) {
        
        self.balancesDetails.accept(self.removingElementWithAsset(
            asset,
            from: self.balancesDetailsValue
        ))
    }
    
    private func removingElementWithAsset(
        _ asset: Asset,
        from sequence: [BalanceState]
        ) -> [BalanceState] {
        
        var newSequence = sequence
        
        while let index = newSequence.index(where: { (state) -> Bool in
            return state.asset == asset
        }) {
            newSequence.remove(at: index)
        }
        
        return newSequence
    }
    
    private func appendingElement(
        _ details: BalanceState,
        to sequence: [BalanceState]
        ) -> [BalanceState] {
        
        var newSequence = self.removingElementWithAsset(
            details.asset,
            from: sequence
        )
        
        newSequence.append(details)
        return newSequence
    }
}

extension BalancesRepo {
    
    public enum BalanceState {
        
        /// Balance for the asset is creating
        case creating(Asset)
        
        /// Balance for the asset already created
        case created(BalanceDetails)
    }
}

extension BalancesRepo.BalanceState: Equatable {
    
    public typealias SelfType = BalancesRepo.BalanceState
    
    public static func ==(left: SelfType, right: SelfType) -> Bool {
        switch (left, right) {
        case (.creating(let left), .creating(let right)):
            return left == right
        case (.created(let left), .created(let right)):
            return left == right
        default:
            return false
        }
    }
}

extension BalancesRepo.BalanceState {
    
    var asset: String {
        switch self {
        case .creating(let balanceAsset):
            return balanceAsset
        case .created(let balanceDetails):
            return balanceDetails.asset
        }
    }
}

extension TokenDSDK.BalanceDetails: Equatable {
    
    public typealias SelfType = TokenDSDK.BalanceDetails
    
    public static func ==(left: SelfType, right: SelfType) -> Bool {
        return left.balanceId == right.balanceId
    }
}

extension BalancesRepo {
    
    public enum LoadingStatus {
        
        case loading
        case loaded
    }
}
