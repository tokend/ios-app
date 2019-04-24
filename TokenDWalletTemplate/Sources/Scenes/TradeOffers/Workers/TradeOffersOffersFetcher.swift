import Foundation
import DLJSONAPI
import RxCocoa
import RxSwift
import TokenDSDK

extension TradeOffers {
    
    public class OffersFetcher {
        
        private class RequestModel {
            
            public let isBuy: Bool
            public var pageSize: Int = 10
            public var cancelable: TokenDSDK.Cancelable?
            public var prevRequest: JSONAPI.RequestModel?
            public var prevLinks: Links?
            public var isLoadingMore: LoadingStatus = .loaded
            
            public let items: BehaviorRelay<[Model.Offer]> = BehaviorRelay(value: [])
            public let loadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
            public let errorStatus: PublishRelay<Swift.Error> = PublishRelay()
            
            // MARK: -
            
            public init(isBuy: Bool) {
                self.isBuy = isBuy
            }
            
            // MARK: - Public
            
            public func cancel() {
                
            }
        }
        
        // MARK: - Private properties
        
        private let orderBookApiV3: TokenDSDK.OrderBookApiV3
        private let baseAsset: String
        private let quoteAsset: String
        
        private var buyRequest: RequestModel = RequestModel(isBuy: true)
        private var sellRequest: RequestModel = RequestModel(isBuy: false)
        
        // MARK: -
        
        public init(
            orderBookApiV3: TokenDSDK.OrderBookApiV3,
            baseAsset: String,
            quoteAsset: String
            ) {
            
            self.orderBookApiV3 = orderBookApiV3
            self.baseAsset = baseAsset
            self.quoteAsset = quoteAsset
        }
        
        // MARK: - Private
        
        private func getRequestModel(_ isBuy: Bool) -> RequestModel {
            return isBuy ? self.buyRequest : self.sellRequest
        }
        
        private func loadOffers(request: RequestModel, pageSize: Int) {
            request.pageSize = pageSize
            
            let filters = OrderBookRequestFiltersV3
                .with(.isBuy(request.isBuy))
                .addFilter(.baseAsset(self.baseAsset))
                .addFilter(.quoteAsset(self.quoteAsset))
            
            let paginationStrategy = IndexedPaginationStrategy(
                index: nil,
                limit: pageSize,
                order: .descending
            )
            let pagination = RequestPagination(.strategy(paginationStrategy))
            
            request.loadingStatus.accept(.loading)
            request.cancelable = self.orderBookApiV3.requestOffers(
                orderBookId: "0",
                filters: filters,
                include: ["base_asset", "quote_asset"],
                pagination: pagination,
                onRequestBuilt: { (requestModel) in
                    request.prevRequest = requestModel
            },
                completion: { [weak self] (result) in
                    request.loadingStatus.accept(.loaded)
                    
                    switch result {
                        
                    case .failure(let error):
                        request.errorStatus.accept(error)
                        
                    case .success(let document):
                        request.prevLinks = document.links
                        let offers: [Model.Offer] = self?.mapOffers(document.data ?? []) ?? []
                        request.items.accept(offers)
                    }
            })
        }
        
        private func reloadOffers(request: RequestModel) {
            request.cancel()
            
            self.loadOffers(request: request, pageSize: request.pageSize)
        }
        
        private func loadMoreOffers(request: RequestModel) {
//            guard let prevRequest = request.prevRequest,
//                let links = request.prevLinks,
//                links.next != nil,
//                !request.isLoadingMore else {
//                    return
//            }
//
//            request.isLoadingMore = true
//            self.loadingStatus.accept(.loading)
//            self.api.loadPageForLinks(
//                ParticipantEffectResource.self,
//                links: links,
//                page: .next,
//                previousRequest: prevRequest,
//                shouldSign: true,
//                onRequestBuilt: { [weak self] (prevRequest) in
//                    self?.prevRequest = prevRequest
//                },
//                completion: { [weak self] (result) in
//                    self?.isLoadingMore = false
//                    self?.loadingStatus.accept(.loaded)
//
//                    switch result {
//
//                    case .failure(let error):
//                        self?.errors.accept(error)
//
//                    case .success(let document):
//                        if let history = document.data {
//                            self?.prevLinks = document.links
//                            self?.historyDidLoad(
//                                history: history,
//                                fromLast: true
//                            )
//                        }
//                    }
//            })
        }
        
        private func mapOffers(_ resources: [OrderBookEntryResource]) -> [Model.Offer] {
            let offers: [Model.Offer] = resources.compactMap { (resource) -> Model.Offer? in
                return resource.offer
            }
            
            return offers
        }
    }
}

extension TradeOffers.OffersFetcher: TradeOffers.OffersFetcherProtocol {
    
    public func getItemsValue(_ isBuy: Bool) -> [TradeOffers.Model.Offer] {
        return self.getRequestModel(isBuy).items.value
    }
    
    public func getLoadingStatusValue(_ isBuy: Bool) -> LoadingStatus {
        return self.getRequestModel(isBuy).loadingStatus.value
    }
    
    public func getLoadingMoreStatusValue(_ isBuy: Bool) -> LoadingStatus {
        return self.getRequestModel(isBuy).isLoadingMore
    }
    
    public func observeItems(_ isBuy: Bool, pageSize: Int) -> Observable<[TradeOffers.Model.Offer]> {
        self.loadOffers(request: self.getRequestModel(isBuy), pageSize: pageSize)
        
        return self.getRequestModel(isBuy).items.asObservable()
    }
    
    public func reloadItems(_ isBuy: Bool) {
        self.reloadOffers(request: self.getRequestModel(isBuy))
    }
    
    public func loadMoreItems(_ isBuy: Bool) {
        self.loadMoreOffers(request: self.getRequestModel(isBuy))
    }
    
    public func observeLoadingStatus(_ isBuy: Bool) -> Observable<LoadingStatus> {
        return self.getRequestModel(isBuy).loadingStatus.asObservable()
    }
    
    public func observeErrorStatus(_ isBuy: Bool) -> Observable<Swift.Error> {
        return self.getRequestModel(isBuy).errorStatus.asObservable()
    }
}

extension OrderBookEntryResource {
    fileprivate typealias Model = TradeOffers.Model
    fileprivate typealias Amount = Model.Amount
    fileprivate typealias Offer = Model.Offer
    
    fileprivate var offer: Offer? {
        guard
            let baseAsset = self.baseAsset?.id,
            let quoteAsset = self.quoteAsset?.id else {
                return nil
        }
        
        let amount = Amount(
            value: self.baseAmount,
            currency: baseAsset
        )
        let price = Amount(
            value: self.price,
            currency: quoteAsset
        )
        
        return Model.Offer(
            amount: amount,
            price: price,
            isBuy: self.isBuy
        )
    }
}
