import Foundation
import TokenDSDK
import RxCocoa
import RxSwift

public class SalesRepo {
    
    public typealias Sale = TokenDSDK.SaleResponse
    public typealias SaleDetails = TokenDSDK.SaleDetailsResponse
    
    // MARK: - Private properties
    
    private let api: TokenDSDK.SalesApi
    private let originalAccountId: String
    
    private let sales: BehaviorRelay<[Sale]> = BehaviorRelay(value: [])
    private let loadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
    private let loadingMoreStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
    private var errorStatus: PublishRelay<Swift.Error> = PublishRelay()
    
    private let disposeBag = DisposeBag()
    private let pageSize: Int = 25
    private var currentPage: Int = 0
    
    private var shouldInitiateLoad: Bool = true
    private var shouldLoadMore: Bool = false
    
    // MARK: - Public properties
    
    public var salesValue: [Sale] {
        return self.sales.value
    }
    public var loadingStatusValue: LoadingStatus {
        return self.loadingStatus.value
    }
    public var loadingMoreStatusValue: LoadingStatus {
        return self.loadingMoreStatus.value
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
        
        self.currentPage = fromLast ? self.currentPage + 1 : self.currentPage
        
        self.api.getSales(
            SaleResponse.self,
            limit: self.pageSize,
            cursor: fromLast ? self.salesValue.last?.pagingToken : nil,
            page: self.currentPage,
            owner: nil,
            name: nil,
            baseAsset: nil,
            openOnly: true,
            completion: { [weak self] (result) in
                switch result {
                    
                case .success(let sales):
                    let pageSize = self?.pageSize ?? 0
                    self?.shouldLoadMore = sales.count == pageSize
                    if fromLast && sales.isEmpty {
                        completion()
                        return
                    }
                    
                    var newSales: [Sale] = []
                    if fromLast {
                        newSales = self?.salesValue ?? []
                    }
                    newSales.append(contentsOf: sales)
                    self?.sales.accept(newSales)
                    
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
    
    public func loadMoreSales() {
        guard self.shouldLoadMore else {
            self.loadingMoreStatus.accept(.loaded)
            return
        }
        
        self.loadingMoreStatus.accept(.loading)
        self.loadSales(fromLast: true, completion: { [weak self] in
            self?.loadingMoreStatus.accept(.loaded)
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
    
    public func observeLoadingMoreStatus() -> Observable<LoadingStatus> {
        return self.loadingMoreStatus.asObservable()
    }
    
    public func observeErrorStatus() -> Observable<Swift.Error> {
        return self.errorStatus.asObservable()
    }
}

extension SalesRepo {
    
    public enum LoadingStatus {
        
        case loading
        case loaded
    }
}
