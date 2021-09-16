import Foundation
import TokenDSDK
import TokenDWallet
import DLCryptoKit
import RxCocoa
import RxSwift

class BalancesRepo {

    typealias AssetCode = String
    typealias BalanceIdentifier = String

    // MARK: - Private properties

    private let accountRepo: AccountRepo
    private let transactionSender: TransactionSender
    private let transactionCreator: TransactionCreator
    private let originalAccountId: String

    private let disposeBag = DisposeBag()
    
    private var shouldInitiateLoad: Bool = true
    
    private let balancesDetailsBehaviorRelay: BehaviorRelay<[BalanceState]> = BehaviorRelay(value: [])
    private var loadingStatusBehaviorRelay: BehaviorRelay<LoadingStatus> = BehaviorRelay<LoadingStatus>(value: .loaded)
    private let errorStatusPublishRelay: PublishRelay<Swift.Error> = PublishRelay()

    private var timer: Timer?

    // MARK: - Public properties
    
    public var balancesDetails: [BalanceState] {
        return self.balancesDetailsBehaviorRelay.value
    }
    
    public var loadingStatus: LoadingStatus {
        return self.loadingStatusBehaviorRelay.value
    }
    
    // MARK: -
    
    init(
        accountRepo: AccountRepo,
        transactionSender: TransactionSender,
        transactionCreator: TransactionCreator,
        originalAccountId: String
        ) {

        self.accountRepo = accountRepo
        self.transactionSender = transactionSender
        self.transactionCreator = transactionCreator
        self.originalAccountId = originalAccountId

        self.observeRepoErrorStatus()

        timer = .scheduledTimer(
            withTimeInterval: 4.0,
            repeats: true,
            block: { [weak self] (timer) in
                self?.reloadBalancesDetails()
        })

        timer?.fire()
    }
    
    deinit {
        timer?.invalidate()
    }
}

// MARK: - Public methods

extension BalancesRepo {
    
    func observeBalancesDetails() -> Observable<[BalanceState]> {
        if self.shouldInitiateLoad {
            self.shouldInitiateLoad = false
            self.reloadBalancesDetails()
        }
        return self.balancesDetailsBehaviorRelay.asObservable()
    }
    
    func observeLoadingStatus() -> Observable<LoadingStatus> {
        return loadingStatusBehaviorRelay.asObservable()
    }
    
    func observeErrorStatus() -> Observable<Swift.Error> {
        return self.errorStatusPublishRelay.asObservable()
    }
    
    enum ReloadBalanceDetailsResult {
        case succeeded(balances: [Balance])
        case failed(Swift.Error)
    }
    func reloadBalancesDetails(
        _ completion: ((ReloadBalanceDetailsResult) -> Void)? = nil
        ) {

        self.loadingStatusBehaviorRelay.accept(.loading)

        self.accountRepo.updateAccount(completion: { [weak self] (result) in

            switch result {

            case .failure(let error):
                completion?(.failed(error))

            case .success(let account):
                let balances = account.balances.mapToBalances()
                self?.saveBalances(balances)
                completion?(.succeeded(balances: balances))
            }

            self?.loadingStatusBehaviorRelay.accept(.loaded)
        })
    }

    enum CreateBalanceError: Swift.Error {
        case failedToGetAccountID
    }
    enum CreateBalanceResult {
        case succeeded
        case failure(Swift.Error)
    }
    func createBalanceForAsset(
        _ asset: AssetCode,
        completion: @escaping (CreateBalanceResult) -> Void
        ) {

        
        guard balancesDetails.first(where: { (state) -> Bool in
            return state.asset == asset
        }) == nil
            else {
                completion(.succeeded)
                return
        }

        let new = appendingElement(.creating(asset), to: balancesDetails)
        self.balancesDetailsBehaviorRelay.accept(new)

        createBalance(
            asset: asset,
            completion: completion
        )
    }
    
    func reloadBalances() {
        reloadBalancesDetails()
    }
}

// MARK: - Private methods

private extension BalancesRepo {

    func saveBalances(
        _ balances: [Balance]
    ) {
        let new = merge(balancesStates: balancesDetails, with: balances)
        balancesDetailsBehaviorRelay.accept(new)
    }

    func observeRepoErrorStatus() {
        self.errorStatusPublishRelay
            .asObservable()
            .subscribe(onNext: { [weak self] (_) in
                self?.shouldInitiateLoad = true
            })
            .disposed(by: self.disposeBag)
    }

    func createBalance(
        asset: AssetCode,
        completion: @escaping (CreateBalanceResult) -> Void
        ) {

        guard let sourceAccountID = AccountID(
            base32EncodedString: originalAccountId,
            expectedVersion: .accountIdEd25519
            ) else {
                completion(.failure(CreateBalanceError.failedToGetAccountID))
                return
        }

        let createBalanceOperation = ManageBalanceOp(
            action: ManageBalanceAction.create,
            destination: sourceAccountID,
            asset: asset,
            ext: .emptyVersion
        )

        buildTransaction(
            asset: asset,
            with: createBalanceOperation,
            sourceAccountID: sourceAccountID,
            completion: completion
        )
    }

    func buildTransaction(
        asset: AssetCode,
        with createBalanceOperation: ManageBalanceOp,
        sourceAccountID: AccountID,
        completion: @escaping(CreateBalanceResult) -> Void
    ) {

        transactionCreator.createTransaction(
            sourceAccountId: sourceAccountID,
            operations: [
                .manageBalance(createBalanceOperation)
            ],
            sendDate: Date(),
            completion: { [weak self] (result) in

                switch result {

                case .success(let transaction):
                    self?.sendTransaction(
                        asset: asset,
                        transaction: transaction,
                        completion: completion
                    )

                case .failure(let error):
                    completion(.failure(error))
                }
        })
    }

    func sendTransaction(
        asset: AssetCode,
        transaction: TransactionModel,
        completion: @escaping(CreateBalanceResult) -> Void
    ) {

        transactionSender.sendTransactionV3(
            transaction,
            completion: { [weak self] (result) in
                switch result {

                case .succeeded:
                    self?.reloadBalancesDetails({ (_) in
                        completion(.succeeded)
                    })

                case .failed(let error):
                    completion(.failure(error))
                }
        })
    }
}

// MARK: - Edit sequence methods

private extension BalancesRepo {

    func merge(
        balancesStates: [BalanceState],
        with balances: [Balance]
    ) -> [BalanceState] {

        var newBalanceStates = balancesStates.filter { (state) -> Bool in
            switch state {
            case .creating:
                return true
            case .created:
                return false
            }
        }

        for balance in balances {
            newBalanceStates = self.appendingElement(.created(balance), to: newBalanceStates)
        }

        return newBalanceStates
    }
    
    func removingElementWithAsset(
        _ asset: AssetCode,
        from sequence: [BalanceState]
        ) -> [BalanceState] {
        
        var newSequence = sequence
        
        while let index = newSequence.firstIndex(where: { (state) -> Bool in
            return state.asset == asset
        }) {
            newSequence.remove(at: index)
        }
        
        return newSequence
    }
    
    func appendingElement(
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
    
    enum BalanceState: Equatable {
        
        /// Balance for the asset is creating
        case creating(String)
        
        /// Balance for the asset already created
        case created(Balance)
    }
}

extension BalancesRepo.BalanceState {
    
    var asset: String {
        switch self {
        case .creating(let asset):
            return asset
        case .created(let balance):
            return balance.asset.asset
        }
    }
}

extension BalancesRepo {
    
    enum LoadingStatus {
        
        case loading
        case loaded
    }
}

extension BalancesRepo {

    struct Balance: Equatable {

        let id: BalanceIdentifier
        let asset: Asset
        let balance: Decimal
    }
}

extension BalancesRepo.Balance {

    struct Asset: Equatable {

        let id: String
        let asset: String
        let trailingDigits: NewAmountFormatter.TrailingDigits
    }
}

extension Array where Element == AccountRepo.Account.Balance {

    func mapToBalances() -> [BalancesRepo.Balance] {

        map { $0.mapToBalance() }
    }

    func mapToBalancesStates() -> [BalancesRepo.BalanceState] {

        map { $0.mapToBalanceState() }
    }
}

extension AccountRepo.Account.Balance {

    func mapToBalance() -> BalancesRepo.Balance {

        .init(
            id: id,
            asset: asset.mapToAsset(),
            balance: balance
        )
    }

    func mapToBalanceState() -> BalancesRepo.BalanceState {

        .created(mapToBalance())
    }
}

extension AccountRepo.Account.Balance.Asset {

    func mapToAsset() -> BalancesRepo.Balance.Asset {

        .init(
            id: id,
            asset: asset,
            trailingDigits: trailingDigits
        )
    }
}
