import Foundation
import RxCocoa
import RxSwift
import TokenDSDK

class AccountRepo {
    
    enum LoadingStatus {
        case loading
        case loaded
    }
    
    typealias Account = Horizon.AccountResource
    
    // MARK: - Private properties
    
    private let account: BehaviorRelay<Account?> = BehaviorRelay(value: nil)
    private let loadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
    private let errorStatus: PublishRelay<Swift.Error> = PublishRelay()
    private let apiV3: TokenDSDK.APIv3
    private let originalAccountId: String
    
    private let externalSystemIds: String = "external_system_ids"
    
    // MARK: - Public properties
    
    public var accountValue: Account? {
        return self.account.value
    }
    
    public var loadingStatusValue: LoadingStatus {
        return self.loadingStatus.value
    }
    
    // MARK: -
    
    init(
        apiV3: TokenDSDK.APIv3,
        originalAccountId: String
        ) {
        
        self.apiV3 = apiV3
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
        case failed(Error)
        
        enum Error {
            case empty
            case other(Swift.Error)
        }
    }
    public func updateAccount(
        _ completion: @escaping (UpdateAccountResult) -> Void
        ) {
        
        self.loadingStatus.accept(.loading)
        self.apiV3.accountsApi.requestAccount(
            accountId: self.originalAccountId,
            include: [self.externalSystemIds],
            pagination: nil,
            completion: { [weak self] (result) in
                switch result {
                    
                case .failure(let error):
                    self?.errorStatus.accept(error)
                    completion(.failed(.other(error)))
                    
                case .success(let document):
                    guard let account = document.data else {
                        return
                    }
                    self?.account.accept(account)
                    completion(.succeeded)
                }
            }
        )
    }
}
