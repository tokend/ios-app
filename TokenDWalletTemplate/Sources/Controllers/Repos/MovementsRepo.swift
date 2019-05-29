import Foundation
import TokenDSDK
import TokenDWallet
import RxSwift
import RxCocoa
import DLJSONAPI

class MovementsRepo {
    
    // MARK: - Private properties
    
    private let api: HistoryApiV3
    private let accountId: String
    
    private let movements: BehaviorRelay<[ParticipantEffectResource]> = BehaviorRelay(value: [])
    private let loadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
    private let errors: PublishRelay<Swift.Error> = PublishRelay()
    
    private let pagination: RequestPagination = {
        let strategy = IndexedPaginationStrategy(index: nil, limit: 10, order: .descending)
        return RequestPagination(.strategy(strategy))
    }()
    
    private var prevRequest: JSONAPI.RequestModel?
    private var prevLinks: Links?
    private var isLoadingMore: Bool = false
    
    // MARK: - Includes
    
    private let effect: String = "effect"
    private let operationDetails: String = "operation.details"
    private let operation: String = "operation"
    
    // MARK: - Public propeties
    
    public var movementsValue: [ParticipantEffectResource] {
        return self.movements.value
    }
    
    // MARK: -
    
    init(
        api: HistoryApiV3,
        accountId: String
        ) {
        
        self.api = api
        self.accountId = accountId
    }
    
    // MARK: - Public
    
    func observeMovements() -> Observable<[ParticipantEffectResource]> {
        return self.movements.asObservable()
    }
    
    func observeErrors() -> Observable<Swift.Error> {
        return self.errors.asObservable()
    }
    
    func observeLoadingStatus() -> Observable<LoadingStatus> {
        return self.loadingStatus.asObservable()
    }
    
    func loadMovements(
        fromLast: Bool,
        completion: @escaping () -> Void
        ) {
        
        let filters = HistoryRequestFiltersV3().addFilter(.account(self.accountId))
        
        self.loadingStatus.accept(.loading)
        self.api.requestHistory(
            filters: filters,
            include: [self.effect, self.operationDetails, self.operation],
            pagination: self.pagination,
            onRequestBuilt: { [weak self] (prevRequest) in
                self?.prevRequest = prevRequest
            },
            completion: { [weak self] (result) in
                
                switch result {
                    
                case .failure(let error):
                    self?.errors.accept(error)
                    
                case .success(let document):
                    guard let movements = document.data else {
                        completion()
                        return
                    }
                    self?.prevLinks = document.links
                    self?.movementsDidLoad(
                        movements: movements,
                        fromLast: fromLast
                    )
                }
                completion()
        })
    }
    
    func loadMoreMovements() {
        guard let prevRequest = self.prevRequest,
            let links = self.prevLinks,
            links.next != nil,
            !self.isLoadingMore else {
                return
        }
        
        self.isLoadingMore = true
        self.loadingStatus.accept(.loading)
        self.api.loadPageForLinks(
            ParticipantEffectResource.self,
            links: links,
            page: .next,
            previousRequest: prevRequest,
            shouldSign: true,
            onRequestBuilt: { [weak self] (prevRequest) in
                self?.prevRequest = prevRequest
            },
            completion: { [weak self] (result) in
                self?.isLoadingMore = false
                self?.loadingStatus.accept(.loaded)
                
                switch result {
                    
                case .failure(let error):
                    self?.errors.accept(error)
                    
                case .success(let document):
                    guard let movements = document.data else {
                        return
                    }
                    self?.prevLinks = document.links
                    self?.movementsDidLoad(
                        movements: movements,
                        fromLast: true
                    )
                }
        })
    }
    
    func reloadTransactions() {
        self.loadMovements(
            fromLast: false,
            completion: { [weak self] in
                self?.loadingStatus.accept(.loaded)
        })
    }
    
    // MARK: - Private
    
    private func movementsDidLoad(
        movements: [ParticipantEffectResource],
        fromLast: Bool
        ) {
        
        var newMovements: [ParticipantEffectResource] = []
        if fromLast {
            newMovements.append(contentsOf: self.movementsValue)
        }
        
        newMovements.appendUniques(contentsOf: movements)
        self.movements.accept(newMovements)
    }
}

extension MovementsRepo {
    enum LoadingStatus {
        case loading
        case loaded
    }
}
