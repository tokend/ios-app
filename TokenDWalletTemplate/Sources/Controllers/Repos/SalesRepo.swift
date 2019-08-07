import Foundation
import TokenDSDK
import RxCocoa
import RxSwift

class SalesRepo {
    
    typealias Sale = TokenDSDK.SaleResponse
    typealias SaleDetails = TokenDSDK.SaleDetailsResponse
    
    // MARK: - Private properties
    
    private let api: TokenDSDK.SalesApi
    private let originalAccountId: String
    
    private let sales: BehaviorRelay<[Sale]> = BehaviorRelay(value: [])
    private let loadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
    private var errorStatus: PublishRelay<Swift.Error> = PublishRelay()
    
    private let disposeBag = DisposeBag()
    private let pageSize: Int = 20
    
    private var shouldInitiateLoad: Bool = true
    private var shouldLoadMore: Bool = false
    
    // MARK: - Public properties
    
    public var salesValue: [Sale] {
        return self.sales.value
    }
    public var loadingStatusValue: LoadingStatus {
        return self.loadingStatus.value
    }
    
    // MARK: -
    
    init(
        api: TokenDSDK.SalesApi,
        originalAccountId: String
        ) {
        
        self.api = api
        self.originalAccountId = originalAccountId
        
        self.observeRepoErrorStatus()
    }
    
    // MARK: - Private
    
    private func loadSales(
        fromLast: Bool,
        completion: @escaping () -> Void
        ) {
        
        self.api.getSales(
            SaleResponse.self,
            limit: nil,
            cursor: nil,
            page: nil,
            owner: nil,
            name: nil,
            baseAsset: nil,
            openOnly: true,
            completion: { [weak self] (result) in
                switch result {
                    
                case .success(let sales):
                    self?.shouldLoadMore = false
                    self?.sales.accept(sales)
                    
                case .failure(let errors):
                    self?.errorStatus.accept(errors)
                }
                
                completion()
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
    
    // MARK: - Public
    
    public func reloadSales(completion: (() -> Void)? = nil) {
        self.loadingStatus.accept(.loading)
        self.loadSales(fromLast: false, completion: { [weak self] in
            self?.loadingStatus.accept(.loaded)
            completion?()
        })
    }
    
    public func observeSales() -> Observable<[Sale]> {
        if self.shouldInitiateLoad {
            self.shouldInitiateLoad = false
            self.reloadSales()
        }
        return self.sales.asObservable()
    }
    
    public func observeSale(id: String) -> Observable<Sale?> {
        if self.shouldInitiateLoad {
            self.shouldInitiateLoad = false
            self.reloadSales()
        }
        return self.sales.map { $0.first { $0.id == id } }.asObservable()
    }
    
    public func observeLoadingStatus() -> Observable<LoadingStatus> {
        return self.loadingStatus.asObservable()
    }
    
    public func observeErrorStatus() -> Observable<Swift.Error> {
        return self.errorStatus.asObservable()
    }
}

extension SalesRepo {
    enum LoadingStatus {
        case loading
        case loaded
    }
}
