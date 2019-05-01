import Foundation
import RxCocoa
import RxSwift

public enum TradeOffersTradesFetcherLoadingStatus {
    case loaded
    case loading
}

public protocol TradeOffersTradesFetcherProtocol {
    
    typealias LoadingStatus = TradeOffersTradesFetcherLoadingStatus
    typealias Item = TradeOffers.Model.Trade
    
    func getItemsValue() -> [Item]
    func getLoadingStatusValue() -> LoadingStatus
    func getHasMoreItems() -> Bool
    
    func observeItems(pageSize: Int) -> Observable<[Item]>
    func reloadItems()
    func loadMoreItems()
    func observeLoadingStatus() -> Observable<LoadingStatus>
    func observeErrorStatus() -> Observable<Swift.Error>
}

extension TradeOffers {
    
    public typealias TradesFetcherProtocol = TradeOffersTradesFetcherProtocol
}
