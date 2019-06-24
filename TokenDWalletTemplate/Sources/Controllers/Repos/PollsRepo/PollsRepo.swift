import Foundation
import TokenDSDK
import DLJSONAPI
import RxSwift
import RxCocoa

public class PollsRepo {
    
    // MARK: - Private properties
    
    private let pollsApi: PollsApiV3
    private let ownerAccountId: String
    private let voterAccountId: String
    
    private let pagination: RequestPagination = {
        let strategy = IndexedPaginationStrategy(index: nil, limit: 10, order: .descending)
        return RequestPagination(.strategy(strategy))
    }()
    private let loadAllVotesController: LoadAllResourcesController<VoteResource> = {
        let strategy = IndexedPaginationStrategy(index: nil, limit: 50, order: .descending)
        return LoadAllResourcesController(requestPagination: RequestPagination(.strategy(strategy)))
    }()
    private var prevRequest: JSONAPI.RequestModel?
    private var prevLinks: Links?
    private var isLoadingMore: Bool = false
    
    private let polls: BehaviorRelay<[PollResource]> = BehaviorRelay(value: [])
    private let votes: BehaviorRelay<[VoteResource]> = BehaviorRelay(value: [])
    private let loadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
    private let errorStatus: PublishRelay<Swift.Error> = PublishRelay()
    
    // MARK: -
    
    init(
        pollsApi: PollsApiV3,
        ownerAccountId: String,
        voterAccountId: String
        ) {
        
        self.pollsApi = pollsApi
        self.ownerAccountId = ownerAccountId
        self.voterAccountId = voterAccountId
    }
    
    // MARK: - Public
    
    func observePolls() -> Observable<[PollResource]> {
        self.loadPolls()
        return self.polls.asObservable()
    }
    
    func observeVotes() -> Observable<[VoteResource]> {
        self.loadVotes()
        return self.votes.asObservable()
    }
    
    func reloadPolls() {
        self.loadPolls()
        self.loadVotes()
    }
    
    func observeLoadingStatus() -> Observable<LoadingStatus> {
        return self.loadingStatus.asObservable()
    }
    
    func observeErrorStatus() -> Observable<Swift.Error> {
        return self.errorStatus.asObservable()
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
        self.pollsApi.loadPageForLinks(
            PollResource.self,
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
                    self?.errorStatus.accept(error)
                    
                case .success(let document):
                    if let polls = document.data {
                        self?.prevLinks = document.links
                        var currentPolls = self?.polls.value ?? []
                        currentPolls.append(contentsOf: polls)
                        self?.polls.accept(currentPolls)
                    }
                }
        })
    }
    
    // MARK: - Private
    
    private func loadPolls() {
        let filter = PollsRequestFiltersV3.with(.owner(self.ownerAccountId))
        self.loadingStatus.accept(.loading)
        _ = self.pollsApi.requestPolls(
            filters: filter,
            pagination: self.pagination,
            onRequestBuilt: { [weak self] (request) in
                self?.prevRequest = request
            },
            completion: { [weak self] (result) in
                self?.loadingStatus.accept(.loaded)
                switch result {
                    
                case .failure(let error):
                    self?.errorStatus.accept(error)
                    
                case .success(let document):
                    guard let polls = document.data else {
                        return
                    }
                    self?.prevLinks = document.links
                    self?.polls.accept(polls)
                }
            }
        )
    }
    
    private func loadVotes() {
        self.loadingStatus.accept(.loading)
        self.loadAllVotesController.loadResources(
            loadPage: { [weak self] (pagination, completion) in
                guard let strongSelf = self else {
                    return
                }
                _ = strongSelf.pollsApi.requestVotesById(
                    voterAccountId: strongSelf.voterAccountId,
                    pagination: pagination,
                    completion: { (result) in
                        switch result {
                            
                        case .failure(let error):
                            completion(.failed(error))
                            
                        case .success(let document):
                            let data = document.data ?? []
                            completion(.succeeded(data))
                        }
                })
        }, completion: { [weak self] (result, data) in
            self?.loadingStatus.accept(.loaded)
            switch result {
                
            case .failed(let error):
                self?.votes.accept(data)
                self?.errorStatus.accept(error)
                
            case .succeded:
                self?.votes.accept(data)
            }
        })
    }
}

extension PollsRepo {
    
    public enum LoadingStatus {
        case loaded
        case loading
    }
}
