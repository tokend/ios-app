import Foundation
import DLJSONAPI
import RxCocoa
import RxSwift
import TokenDSDK

extension TradeOffers {
    
    public class TradesFetcher {
        
        // MARK: - Private properties
        
        private let orderBookApi: TokenDSDK.OrderBookApi
        private let baseAsset: String
        private let quoteAsset: String
        
        private var pageSize: Int = 10
        private var cancelable: TokenDSDK.Cancelable?
        private var prevCursor: String?
        private var hasMoreItems: Bool = true
        private var isLoadingMore: Bool = false
        
        private let items: BehaviorRelay<[Model.Trade]> = BehaviorRelay(value: [])
        private let loadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
        private let errorStatus: PublishRelay<Swift.Error> = PublishRelay()
        
        // MARK: -
        
        public init(
            orderBookApi: TokenDSDK.OrderBookApi,
            baseAsset: String,
            quoteAsset: String
            ) {
            
            self.orderBookApi = orderBookApi
            self.baseAsset = baseAsset
            self.quoteAsset = quoteAsset
        }
        
        // MARK: - Private
        
        private func loadTrades(pageSize: Int) {
            self.pageSize = pageSize
            
            let parameters = TradesRequestParameters(
                baseAsset: self.baseAsset,
                quoteAsset: self.quoteAsset,
                orderBookId: "0"
            )
            
            self.loadingStatus.accept(.loading)
            
            self.orderBookApi.requestTrades(
                parameters: parameters,
                orderDescending: true,
                limit: pageSize,
                cursor: nil,
                completion: { [weak self] (result) in
                    self?.loadingStatus.accept(.loaded)
                    
                    switch result {
                        
                    case .success(let trades):
                        if let id = trades.last?.id {
                            self?.prevCursor = "\(id)"
                        }
                        self?.onItemsLoaded(responses: trades, shouldAppend: false)
                        
                    case .failure(let error):
                        self?.errorStatus.accept(error)
                    }
            })
        }
        
        private func reloadTrades() {
            self.cancelLoading()
            
            self.loadTrades(pageSize: self.pageSize)
        }
        
        private func loadMoreTrades() {
            guard
                let prevCursor = self.prevCursor,
                !self.isLoadingMore else {
                    return
            }
            
            guard self.hasMoreItems else {
                print("no more items")
                return
            }
            
            self.isLoadingMore = true
            
            let parameters = TradesRequestParameters(
                baseAsset: self.baseAsset,
                quoteAsset: self.quoteAsset,
                orderBookId: "0"
            )
            
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                self.orderBookApi.requestTrades(
                    parameters: parameters,
                    orderDescending: true,
                    limit: self.pageSize,
                    cursor: prevCursor,
                    completion: { [weak self] (result) in
                        self?.isLoadingMore = false
                        
                        switch result {
                            
                        case .success(let trades):
                            if let id = trades.last?.id {
                                self?.prevCursor = "\(id)"
                            }
                            self?.onItemsLoaded(responses: trades, shouldAppend: true)
                            
                        case .failure(let error):
                            self?.errorStatus.accept(error)
                        }
                })
            })
        }
        
        private func cancelLoading() {
            self.cancelable?.cancel()
            self.cancelable = nil
            self.loadingStatus.accept(.loaded)
            self.isLoadingMore = false
        }
        
        private func onItemsLoaded(
            responses: [TradeResponse],
            shouldAppend: Bool
            ) {
            
            self.hasMoreItems = responses.count >= self.pageSize
            
            let newItems: [Model.Trade] = self.mapItems(responses)
            
            if shouldAppend {
                var prevItems = self.getItemsValue()
                prevItems.appendUniques(contentsOf: newItems)
                self.items.accept(prevItems)
            } else {
                self.items.accept(newItems)
            }
        }
        
        private func mapItems(_ items: [TradeResponse]) -> [Model.Trade] {
            var previousPrice: Decimal = 0
            let models: [Model.Trade] = items.compactMap { (item) -> Model.Trade? in
                let model = item.getTrade(previousPrice: previousPrice)
                
                previousPrice = model.price
                
                return model
            }
            
            return models
        }
    }
}

extension TradeOffers.TradesFetcher: TradeOffers.TradesFetcherProtocol {
    
    public func getItemsValue() -> [Item] {
        return self.items.value
    }
    
    public func getLoadingStatusValue() -> LoadingStatus {
        return self.loadingStatus.value
    }
    
    public func getHasMoreItems() -> Bool {
        return self.hasMoreItems
    }
    
    public func observeItems(pageSize: Int) -> Observable<[Item]> {
        self.loadTrades(pageSize: pageSize)
        
        return self.items.asObservable()
    }
    
    public func reloadItems() {
        self.reloadTrades()
    }
    
    public func loadMoreItems() {
        self.loadMoreTrades()
    }
    
    public func observeLoadingStatus() -> Observable<LoadingStatus> {
        return self.loadingStatus.asObservable()
    }
    
    public func observeErrorStatus() -> Observable<Swift.Error> {
        return self.errorStatus.asObservable()
    }
}

extension TradeResponse {
    fileprivate typealias Model = TradeOffers.Model
    fileprivate typealias Trade = Model.Trade
    
    fileprivate func getTrade(previousPrice: Decimal) -> Trade {
        let priceGrows = self.price >= previousPrice
        
        return Trade(
            amount: self.baseAmount,
            price: self.price,
            date: self.createdAt,
            priceGrows: priceGrows
        )
    }
}
