import Foundation
import RxCocoa
import RxSwift

public enum TradeOffersOffersFetcherLoadingStatus {
    case loaded
    case loading
}

public protocol TradeOffersOffersFetcherProtocol {
    
    typealias LoadingStatus = TradeOffersOffersFetcherLoadingStatus
    typealias OrderBook = TradeOffers.Model.OrderBook
    
    func getOrderBookValue() -> OrderBook
    func getLoadingStatusValue() -> LoadingStatus
    
    func observeOrderBook(pageSize: Int) -> Observable<OrderBook>
    func reloadOrderBook()
    func observeLoadingStatus() -> Observable<LoadingStatus>
    func observeErrorStatus() -> Observable<Swift.Error>
}

extension TradeOffers {
    
    public typealias OffersFetcherProtocol = TradeOffersOffersFetcherProtocol
}
