import UIKit
import RxSwift
import RxCocoa

enum TradeableAssetsFetcherLoadingStatus {
    case loading
    case loaded
}

protocol TradeableAssetsFetcherProtocol {
    
    typealias Asset = Trade.Model.Asset
    typealias LoadingStatus = TradeableAssetsFetcherLoadingStatus
    
    var assets: [Asset] { get }
    func updateAssets()
    func observeAssets() -> Observable<[Asset]>
    func observeAssetsLoadingStatus() -> Observable<LoadingStatus>
    func observeAssetsError() -> Observable<Swift.Error>

}

extension Trade {
    typealias AssetsFetcherProtocol = TradeableAssetsFetcherProtocol
}
