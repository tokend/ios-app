import Foundation
import RxCocoa
import RxSwift
import TokenDSDK

class AccountRepo {
    
    enum LoadingStatus {
        case loading
        case loaded
    }

    typealias AccountIdentifier = String
    
    // MARK: - Private properties
    
    private let account: BehaviorRelay<Account?> = BehaviorRelay(value: nil)
    private let loadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
    private let errorStatus: PublishRelay<Swift.Error> = PublishRelay()
    private let accountsApiV3: TokenDSDK.AccountsApiV3
    private let originalAccountId: String
    
    // MARK: - Public properties
    
    public var accountValue: Account? {
        return self.account.value
    }
    
    public var loadingStatusValue: LoadingStatus {
        return self.loadingStatus.value
    }
    
    // MARK: -
    
    init(
        apiV3: TokenDSDK.AccountsApiV3,
        originalAccountId: String
        ) {
        
        self.accountsApiV3 = apiV3
        self.originalAccountId = originalAccountId

        updateAccount()
    }
    
    // MARK: - Private
    
    // MARK: - Public
    
    public func observeAccount() -> Observable<Account?> {
        return self.account.asObservable()
    }
    
    public func observeLoadingStatus() -> Observable<LoadingStatus> {
        return self.loadingStatus.asObservable()
    }
    
    public func observeErrorStatus() -> Observable<Swift.Error> {
        return self.errorStatus.asObservable()
    }
    
    enum UpdateAccountError: Error {
        case empty
    }
    public func updateAccount(
        completion: ((Result<Account, Swift.Error>) -> Void)? = nil
    ) {

        guard loadingStatusValue != .loading
            else {
                var accountDisposable: Disposable?
                var errorDisposable: Disposable?
                accountDisposable = self
                    .account
                    .subscribe(onNext: { (account) in

                        if let account = account {
                            completion?(.success(account))
                        }

                        accountDisposable?.dispose()
                        errorDisposable?.dispose()
                    })

                errorDisposable = self
                    .errorStatus
                    .subscribe(onNext: { (error) in

                        completion?(.failure(error))
                        accountDisposable?.dispose()
                        errorDisposable?.dispose()
                    })
                return
        }

        self.loadingStatus.accept(.loading)
        self.accountsApiV3.requestAccount(
            accountId: self.originalAccountId,
            include: ["balances", "balances.asset", "balances.state", "kyc_data"],
            pagination: nil,
            completion: { [weak self] (result) in
                self?.loadingStatus.accept(.loaded)

                switch result {
                    
                case .failure(let error):
                    self?.errorStatus.accept(error)
                    completion?(.failure(error))

                case .success(let document):
                    guard let rawAccount = document.data,
                        let account = try? rawAccount.mapToAccount()
                        else {
                            self?.errorStatus.accept(UpdateAccountError.empty)
                            completion?(.failure(UpdateAccountError.empty))
                            return
                    }
                    self?.account.accept(account)
                    completion?(.success(account))
                }
            }
        )
    }
}

// MARK: - Account -

extension AccountRepo {

    struct Account {

        let id: AccountIdentifier
        let balances: [Balance]
        let kycData: KYCData?
    }
}

extension AccountRepo.Account {

    struct Balance {

        let id: String
        let asset: Asset
        let balance: Decimal
    }
}

extension AccountRepo.Account.Balance {

    struct Asset {

        let id: String
        let asset: String
        let trailingDigits: NewAmountFormatter.TrailingDigits
    }
}

extension AccountRepo.Account {

    struct KYCData {

        let blobId: String
    }
}

// MARK: - Mappers -

enum AccountMapperError: Error {
    case notEnoughData
}

extension Horizon.AccountResource {

    func mapToAccount() throws -> AccountRepo.Account {

        guard let id = self.id,
            let rawBalances = self.balances
            else {
                throw AccountMapperError.notEnoughData
        }

        let balances = try rawBalances.mapToBalances()
        let kycData: AccountRepo.Account.KYCData?

        if let kyc = self.kycData {
            guard let blobId = kyc.kycData["blobId"] as? String
                else {
                    throw AccountMapperError.notEnoughData
            }
            kycData = .init(
                blobId: blobId
            )
        } else {
            kycData = nil
        }

        return .init(
            id: id,
            balances: balances,
            kycData: kycData
        )
    }
}

enum BalanceMapperError: Error {

    case notEnoughData
}

extension Array where Element == Horizon.BalanceResource {

    func mapToBalances() throws -> [AccountRepo.Account.Balance] {

        try map { (balance) in
            try balance.mapToBalance()
        }
    }
}

extension Horizon.BalanceResource {

    func mapToBalance() throws -> AccountRepo.Account.Balance {

        guard let id = self.id,
            let rawAsset = self.asset,
            let balance = self.state?.available
            else {
                throw BalanceMapperError.notEnoughData
        }

        let asset = try rawAsset.mapToAsset()

        return .init(
            id: id,
            asset: asset,
            balance: balance
        )
    }
}

private enum AssetMapperError: Error {

    case notEnoughData
}

extension Horizon.AssetResource {

    func mapToAsset() throws -> AccountRepo.Account.Balance.Asset {

        guard let id = self.id
            else {
                throw AssetMapperError.notEnoughData
        }

        return .init(
            id: id,
            asset: id,
            trailingDigits: NewAmountFormatter.TrailingDigits(trailingDigits)
        )
    }
}
