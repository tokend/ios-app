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
            public var hasMoreItems: Bool = true
            public var isLoadingMore: Bool = false
            
            public let items: BehaviorRelay<[Model.Offer]> = BehaviorRelay(value: [])
            public let loadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
            public let errorStatus: PublishRelay<Swift.Error> = PublishRelay()
            
            // MARK: -
            
            public init(isBuy: Bool) {
                self.isBuy = isBuy
            }
            
            // MARK: - Public
            
            public func cancel() {
                self.cancelable?.cancel()
                self.cancelable = nil
                self.loadingStatus.accept(.loaded)
                self.isLoadingMore = false
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
                order: request.isBuy ? .descending : .ascending
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
                        self?.onOffersLoaded(
                            request: request,
                            resources: document.data,
                            shouldAppend: false
                        )
                    }
            })
        }
        
        private func reloadOffers(request: RequestModel) {
            request.cancel()
            
            self.loadOffers(request: request, pageSize: request.pageSize)
        }
        
        private func loadMoreOffers(request: RequestModel) {
            guard
                self.getLoadingStatusValue(request.isBuy) == .loaded,
                let prevRequest = request.prevRequest,
                let links = request.prevLinks,
                links.next != nil,
                !request.isLoadingMore else {
                    return
            }
            
            guard request.hasMoreItems else {
                print("no more items")
                return
            }
            
            request.isLoadingMore = true
            request.loadingStatus.accept(.loading)
            
            self.orderBookApiV3.loadPageForLinks(
                OrderBookEntryResource.self,
                links: links,
                page: .next,
                previousRequest: prevRequest,
                shouldSign: true,
                onRequestBuilt: { (prevRequest) in
                    request.prevRequest = prevRequest
            },
                completion: { [weak self] (result) in
                    request.isLoadingMore = false
                    request.loadingStatus.accept(.loaded)
                    
                    switch result {
                        
                    case .failure(let error):
                        request.errorStatus.accept(error)
                        
                    case .success(let document):
                        request.prevLinks = document.links
                        self?.onOffersLoaded(
                            request: request,
                            resources: document.data,
                            shouldAppend: true
                        )
                    }
            })
        }
        
        private func onOffersLoaded(
            request: RequestModel,
            resources: [OrderBookEntryResource]?,
            shouldAppend: Bool
            ) {
            
            let newOffers: [Model.Offer] = self.mapOffers(resources ?? [])
            
            if shouldAppend {
                var prevOffers = self.getItemsValue(request.isBuy)
                prevOffers.appendUniques(contentsOf: newOffers)
                request.items.accept(prevOffers)
            } else {
                request.items.accept(newOffers)
            }
            
            request.hasMoreItems = (resources?.count ?? 0) >= request.pageSize
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
    
    public func getLoadingMoreStatusValue(_ isBuy: Bool) -> Bool {
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
