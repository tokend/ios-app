import UIKit
import RxSwift
import RxCocoa

public enum TradeableAssetsFetcherLoadingStatus {
    case loading
    case loaded
}

public protocol TradeableAssetsFetcherProtocol {
    
    typealias Asset = Trade.Model.Asset
    typealias LoadingStatus = TradeableAssetsFetcherLoadingStatus
    
    var assets: [Asset] { get }
    func updateAssets()
    func observeAssets() -> Observable<[Asset]>
    func observeAssetsLoadingStatus() -> Observable<LoadingStatus>
    func observeAssetsError() -> Observable<Swift.Error>
}

extension Trade {
    public typealias AssetsFetcherProtocol = TradeableAssetsFetcherProtocol
}
