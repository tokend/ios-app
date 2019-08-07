import Foundation
import RxSwift

enum DepositSceneAssetsFetcherLoadingStatus {
    case loading
    case loaded
}

protocol DepositSceneAssetsFetcherProtocol {
    typealias Asset = DepositScene.Model.Asset
    typealias AssetID = DepositScene.AssetID
    typealias LoadingStatus = DepositSceneAssetsFetcherLoadingStatus
    
    var assets: [Asset] { get }
    
    func observeAssets() -> Observable<[Asset]>
    func observeAssetsLoadingStatus() -> Observable<LoadingStatus>
    func observeAssetsErrorStatus() -> Observable<Swift.Error>
    
    func refreshAssets()
    
    func assetForId(_ id: AssetID) -> Asset?
}

extension DepositScene {
    typealias AssetsFetcherProtocol = DepositSceneAssetsFetcherProtocol
}
