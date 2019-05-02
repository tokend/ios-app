import Foundation
import RxCocoa
import RxSwift

public enum TradeOffersOffersFetcherLoadingStatus {
    case loaded
    case loading
}

public protocol TradeOffersOffersFetcherProtocol {
    
    typealias LoadingStatus = TradeOffersOffersFetcherLoadingStatus
    typealias Item = TradeOffers.Model.Offer
    
    func getItemsValue() -> (buyItems: [Item], sellItems: [Item])
    func getLoadingStatusValue() -> LoadingStatus
    
    func observeItems(pageSize: Int) -> Observable<(buyItems: [Item], sellItems: [Item])>
    func reloadItems()
    func observeLoadingStatus() -> Observable<LoadingStatus>
    func observeErrorStatus() -> Observable<Swift.Error>
}

extension TradeOffers {
    
    public typealias OffersFetcherProtocol = TradeOffersOffersFetcherProtocol
}
