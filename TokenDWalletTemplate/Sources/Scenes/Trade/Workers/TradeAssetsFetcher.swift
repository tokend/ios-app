import Foundation
import RxSwift
import RxCocoa
import TokenDSDK

extension Trade {
    
    class AssetsFetcher {
        
        private let assetPairsRepo: AssetPairsRepo
        private let assetsBehaviorRelay = BehaviorRelay(value: [TradeableAssetsFetcherProtocol.Asset]())
        private let assetsLoadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
        private let assetsErrorStatus: PublishRelay<Swift.Error> = PublishRelay()
        private let disposeBag: DisposeBag = DisposeBag()
        
        init(
            assetPairsRepo: AssetPairsRepo
            ) {
            
            self.assetPairsRepo = assetPairsRepo
            
            self.observeAssetPairs()
            self.observeAssetPairsLoadingStatus()
            self.observeAssetPairsErrorStatus()
        }
        
        private func observeAssetPairs() {
            self.assetPairsRepo
                .observeAssetPairs()
                .asObservable()
                .subscribe(onNext: { [weak self] (assetPairs) in
                    let assets = assetPairs
                        .sorted(by: { (left, right) -> Bool in
                            var leftToCompare: String = left.base
                            var rightToCompare: String = right.base
                            if leftToCompare == rightToCompare {
                                leftToCompare = left.quote
                                rightToCompare = right.quote
                            }
                            return leftToCompare < rightToCompare
                        })
                        .filter({ (pair) -> Bool in
                            return pair.meetsPolicy(.tradeableSecondaryMarket)
                        })
                        .map({ (pair) -> TradeableAssetsFetcherProtocol.Asset in
                            return pair.asset
                        })
                    self?.assetsBehaviorRelay.accept(assets)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeAssetPairsLoadingStatus() {
            self.assetPairsRepo
                .observeLoadingStatus()
                .subscribe ( onNext: { [weak self] (status) in
                    self?.assetsLoadingStatus.accept(status.status)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeAssetPairsErrorStatus() {
            self.assetPairsRepo
                .observeErrorStatus()
                .subscribe(onNext: { [weak self] (error) in
                    self?.assetsErrorStatus.accept(error)
                })
                .disposed(by: self.disposeBag)
        }
    }
}

extension Trade.AssetsFetcher: Trade.AssetsFetcherProtocol {
    
    var assets: [TradeableAssetsFetcherProtocol.Asset] {
        return self.assetsBehaviorRelay.value
    }
    
    func updateAssets() {
        self.assetPairsRepo.updateAssetPairs()
    }
    
    func observeAssets() -> Observable<[TradeableAssetsFetcherProtocol.Asset]> {
        return self.assetsBehaviorRelay.asObservable()
    }
    
    func observeAssetsLoadingStatus() -> Observable<LoadingStatus> {
        return self.assetsLoadingStatus.asObservable()
    }
    
    func observeAssetsError() -> Observable<Error> {
        return self.assetsErrorStatus.asObservable()
    }
}

extension AssetPair {
    fileprivate var asset: TradeableAssetsFetcherProtocol.Asset {
        return TradeableAssetsFetcherProtocol.Asset(
            baseAsset: self.base,
            quoteAsset: self.quote,
            currentPrice: self.currentPrice
        )
    }
}

extension AssetPairsRepo.LoadingStatus {
    var status: TradeableAssetsFetcherLoadingStatus {
        switch self {
        case .loaded:
            return .loaded
        case .loading:
            return .loading
        }
    }
}
