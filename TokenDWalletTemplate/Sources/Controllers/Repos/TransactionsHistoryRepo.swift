import Foundation
import TokenDSDK
import TokenDWallet
import RxSwift
import RxCocoa
import DLJSONAPI

class TransactionsHistoryRepo {
    
    // MARK: - Private properties
    
    private let api: HistoryApiV3
    private let balanceId: String
    
    private let transactionsHistory: BehaviorRelay<[ParticipantEffectResource]> = BehaviorRelay(value: [])
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
    
    public var history: [ParticipantEffectResource] {
        return self.transactionsHistory.value
    }
    
    // MARK: -
    
    init(
        api: HistoryApiV3,
        balanceId: String
        ) {
        
        self.api = api
        self.balanceId = balanceId
    }
    
    // MARK: - Public
    
    func observeHistory() -> Observable<[ParticipantEffectResource]> {
        return self.transactionsHistory.asObservable()
    }
    
    func observeErrors() -> Observable<Swift.Error> {
        return self.errors.asObservable()
    }
    
    func observeLoadingStatus() -> Observable<LoadingStatus> {
        return self.loadingStatus.asObservable()
    }
    
    func loadHistory(
        fromLast: Bool,
        completion: @escaping () -> Void
        ) {
        
        let filters = HistoryRequestFiltersV3().addFilter(.balance(self.balanceId))
        
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
                    if let history = document.data {
                        self?.prevLinks = document.links
                        self?.historyDidLoad(
                            history: history,
                            fromLast: fromLast
                        )
                    }
                }
                completion()
        })
    }
    
    func loadMoreHistory() {
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
                    if let history = document.data {
                        self?.prevLinks = document.links
                        self?.historyDidLoad(
                            history: history,
                            fromLast: true
                        )
                    }
                }
        })
    }
    
    func reloadTransactions() {
        self.loadHistory(
            fromLast: false,
            completion: { [weak self] in
                self?.loadingStatus.accept(.loaded)
        })
    }
    
    // MARK: - Private
    
    private func historyDidLoad(
        history: [ParticipantEffectResource],
        fromLast: Bool
        ) {
        
        var newHistory: [ParticipantEffectResource] = []
        if fromLast {
            newHistory.append(contentsOf: self.history)
        }
        
        newHistory.appendUniques(contentsOf: history)
        self.transactionsHistory.accept(newHistory)
    }
}

extension TransactionsHistoryRepo {
    enum LoadingStatus {
        case loading
        case loaded
    }
}
