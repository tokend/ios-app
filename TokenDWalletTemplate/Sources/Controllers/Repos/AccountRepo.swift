import Foundation
import RxCocoa
import RxSwift
import TokenDSDK

class AccountRepo {
    
    enum LoadingStatus {
        case loading
        case loaded
    }
    
    typealias Account = TokenDSDK.AccountResponse
    
    // MARK: - Private properties
    
    private let account: BehaviorRelay<Account?> = BehaviorRelay(value: nil)
    private let loadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
    private let errorStatus: PublishRelay<Swift.Error> = PublishRelay()
    private let api: TokenDSDK.API
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
        api: TokenDSDK.API,
        originalAccountId: String
        ) {
        
        self.api = api
        self.originalAccountId = originalAccountId
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
    
    enum UpdateAccountResult {
        case succeeded
        case failed(TokenDSDK.AccountsApi.RequestAccountResult.RequestError)
    }
    public func updateAccount(
        _ completion: @escaping (UpdateAccountResult) -> Void
        ) {
        self.loadingStatus.accept(.loading)
        self.api.accountsApi.requestAccount(
            accountId: self.originalAccountId,
            completion: { [weak self] (result) in
                self?.loadingStatus.accept(.loaded)
                switch result {
                case .success(let account):
                    self?.account.accept(account)
                    completion(.succeeded)
                case .failure(let error):
                    self?.errorStatus.accept(error)
                    completion(.failed(error))
                }
        })
    }
}
