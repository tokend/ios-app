import Foundation
import TokenDSDK
import RxCocoa
import RxSwift

public class PendingOffersRepo {
    
    public typealias Offer = TokenDSDK.OfferResponse
    
    // MARK: - Private properties
    
    private let api: TokenDSDK.OffersApi
    private let originalAccountId: String
    
    private let offers: BehaviorRelay<[Offer]> = BehaviorRelay(value: [])
    private let loadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
    private let errorStatus: PublishRelay<Swift.Error> = PublishRelay()
    
    private let disposeBag = DisposeBag()
    private let pageSize: Int = 20
    
    private var shouldInitiateLoad: Bool = true
    private var shouldLoadMore: Bool = false
    
    // MARK: - Public properties
    
    public var offersValue: [Offer] {
        return self.offers.value
    }
    public var loadingStatusValue: LoadingStatus {
        return self.loadingStatus.value
    }
    
    // MARK: -
    
    public init(
        api: TokenDSDK.OffersApi,
        originalAccountId: String
        ) {
        
        self.api = api
        self.originalAccountId = originalAccountId
        
        self.observeRepoErrorStatus()
    }
    
    // MARK: - Public
    
    public func reloadOffers(
        completion: (() -> Void)? = nil
        ) {
        self.loadingStatus.accept(.loading)
        self.loadOffers(fromLast: false, completion: { [weak self] in
            self?.loadingStatus.accept(.loaded)
            completion?()
        })
    }
    
    public func observeOffers() -> Observable<[Offer]> {
        if self.shouldInitiateLoad {
            self.shouldInitiateLoad = false
            self.reloadOffers()
        }
        return self.offers.asObservable()
    }
    
    public func observeLoadingStatus() -> Observable<LoadingStatus> {
        return self.loadingStatus.asObservable()
    }
    
    public func observeErrorStatus() -> Observable<Swift.Error> {
        return self.errorStatus.asObservable()
    }
    
    public enum LoadOffersResult {
        case failure(Swift.Error)
        case success([Offer])
    }
    public func loadOffers(
        parameters: TokenDSDK.OffersOffersRequestParameters,
        completion: @escaping (_ result: LoadOffersResult) -> Void
        ) {
        
        self.api.requestOffers(
            accountId: self.originalAccountId,
            parameters: parameters,
            completion: { (result) in
                switch result {
                    
                case .failure(let errors):
                    completion(.failure(errors))
                    
                case .success(let offers):
                    completion(.success(offers))
                }
        })
    }
    
    // MARK: - Private
    
    private func loadOffers(
        fromLast: Bool,
        completion: @escaping () -> Void
        ) {
        
        let parameters = TokenDSDK.OffersOffersRequestParameters(
            isBuy: nil,
            order: "desc",
            baseAsset: nil,
            quoteAsset: nil,
            orderBookId: nil,
            offerId: fromLast ? self.offersValue.last?.pagingToken : nil
        )
        
        self.api.requestOffers(
            accountId: self.originalAccountId,
            parameters: parameters) { [weak self] (result) in
                switch result {
                    
                case .success(let offers):
                    self?.shouldLoadMore = false
                    if fromLast && offers.isEmpty {
                        completion()
                        return
                    }
                    var newOffers: [Offer] = []
                    if fromLast {
                        newOffers = self?.offersValue ?? []
                    }
                    newOffers.append(contentsOf: offers)
                    self?.offers.accept(newOffers)
                    
                case .failure(let errors):
                    self?.errorStatus.accept(errors)
                }
                completion()
        }
    }
    
    private func observeRepoErrorStatus() {
        self.errorStatus
            .asObservable()
            .subscribe(onNext: { [weak self] (_) in
                self?.shouldInitiateLoad = true
            })
            .disposed(by: self.disposeBag)
    }
}

extension PendingOffersRepo {
    public enum LoadingStatus {
        case loading
        case loaded
    }
}
