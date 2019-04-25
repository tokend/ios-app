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
    
    func getItemsValue(_ isBuy: Bool) -> [Item]
    func getLoadingStatusValue(_ isBuy: Bool) -> LoadingStatus
    func getLoadingMoreStatusValue(_ isBuy: Bool) -> Bool
    
    func observeItems(_ isBuy: Bool, pageSize: Int) -> Observable<[Item]>
    func reloadItems(_ isBuy: Bool)
    func loadMoreItems(_ isBuy: Bool)
    func observeLoadingStatus(_ isBuy: Bool) -> Observable<LoadingStatus>
    func observeErrorStatus(_ isBuy: Bool) -> Observable<Swift.Error>
}

extension TradeOffers {
    
    public typealias OffersFetcherProtocol = TradeOffersOffersFetcherProtocol
}
