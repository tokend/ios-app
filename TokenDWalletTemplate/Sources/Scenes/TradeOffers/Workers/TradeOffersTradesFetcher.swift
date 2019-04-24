import Foundation
import DLJSONAPI
import RxCocoa
import RxSwift
import TokenDSDK

extension TradeOffers {
    
    public class TradesFetcher {
        
        // MARK: - Private properties
        
        private let orderBookApi: TokenDSDK.OrderBookApi
        
        public var cancelable: TokenDSDK.Cancelable?
        public var isLoadingMore: LoadingStatus = .loaded
        
        public let items: BehaviorRelay<[Model.Trade]> = BehaviorRelay(value: [])
        public let loadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
        public let errorStatus: PublishRelay<Swift.Error> = PublishRelay()
        
        // MARK: -
        
        public init(orderBookApi: TokenDSDK.OrderBookApi) {
            self.orderBookApi = orderBookApi
        }
        
        // MARK: - Private
        
        private func loadTrades() {
            
        }
        
        private func reloadTrades() {
            
        }
        
        private func loadMoreTrades() {
            
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
    
    public func getLoadingMoreStatusValue() -> LoadingStatus {
        return self.isLoadingMore
    }
    
    public func observeItems() -> Observable<[Item]> {
        self.loadTrades()
        
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
