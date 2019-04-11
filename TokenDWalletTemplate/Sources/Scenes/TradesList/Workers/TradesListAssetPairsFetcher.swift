import Foundation
import RxSwift
import RxCocoa
import TokenDSDK

extension TradesList {
    
    public class AssetPairsFetcher {
        
        public typealias AssetPair = TradesList.Model.AssetPair
        
        // MARK: - Private properties
        
        private let assetPairsRepo: AssetPairsRepo
        private let assetsBehaviorRelay = BehaviorRelay(value: [AssetPair]())
        private let assetsLoadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
        private let assetsErrorStatus: PublishRelay<Swift.Error> = PublishRelay()
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: -
        
        public init(assetPairsRepo: AssetPairsRepo) {
            self.assetPairsRepo = assetPairsRepo
        }
        
        // MARK: - Private
        
        private func observeRepoAssetPairs() {
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
                        .map({ (pair) -> TradesList.AssetPairsFetcherProtocol.AssetPair in
                            return pair.assetPair
                        })
                    self?.assetsBehaviorRelay.accept(assets)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeRepoAssetPairsLoadingStatus() {
            self.assetPairsRepo
                .observeLoadingStatus()
                .subscribe(onNext: { [weak self] (status) in
                    self?.assetsLoadingStatus.accept(status.status)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeRepoAssetPairsErrorStatus() {
            self.assetPairsRepo
                .observeErrorStatus()
                .subscribe(onNext: { [weak self] (error) in
                    self?.assetsErrorStatus.accept(error)
                })
                .disposed(by: self.disposeBag)
        }
    }
}

extension TradesList.AssetPairsFetcher: TradesList.AssetPairsFetcherProtocol {
    
    public var assetsPairs: [AssetPair] {
        return self.assetsBehaviorRelay.value
    }
    
    public func updateAssetPairs() {
        self.assetPairsRepo.updateAssetPairs()
    }
    
    public func observeAssetPairs() -> Observable<[AssetPair]> {
        self.observeRepoAssetPairs()
        
        return self.assetsBehaviorRelay.asObservable()
    }
    
    public func observeAssetPairsLoadingStatus() -> Observable<LoadingStatus> {
        self.observeRepoAssetPairsLoadingStatus()
        
        return self.assetsLoadingStatus.asObservable()
    }
    
    public func observeAssetPairsError() -> Observable<Error> {
        self.observeRepoAssetPairsErrorStatus()
        
        return self.assetsErrorStatus.asObservable()
    }
}

extension TokenDSDK.AssetPair {
    fileprivate var assetPair: TradesList.AssetPairsFetcherProtocol.AssetPair {
        return TradesList.AssetPairsFetcherProtocol.AssetPair(
            baseAsset: self.base,
            quoteAsset: self.quote,
            currentPrice: self.currentPrice
        )
    }
}

extension AssetPairsRepo.LoadingStatus {
    fileprivate var status: TradesList.AssetPairsFetcherProtocol.LoadingStatus {
        switch self {
        case .loaded:
            return .loaded
        case .loading:
            return .loading
        }
    }
}
