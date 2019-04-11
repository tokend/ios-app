import UIKit
import RxSwift
import RxCocoa

public enum TradesListAssetPairsFetcherLoadingStatus {
    case loading
    case loaded
}

public protocol TradesListAssetPairsFetcherProtocol {
    
    typealias AssetPair = TradesList.Model.AssetPair
    typealias LoadingStatus = TradesListAssetPairsFetcherLoadingStatus
    
    var assetsPairs: [AssetPair] { get }
    func updateAssetPairs()
    func observeAssetPairs() -> Observable<[AssetPair]>
    func observeAssetPairsLoadingStatus() -> Observable<LoadingStatus>
    func observeAssetPairsError() -> Observable<Swift.Error>
}

extension TradesList {
    public typealias AssetPairsFetcherProtocol = TradesListAssetPairsFetcherProtocol
}
