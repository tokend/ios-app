import Foundation
import RxCocoa
import RxSwift

class RateProvider {
    
    // MARK: - Private properties
    
    private let assetPairsRepo: AssetPairsRepo
    private let rateEventBaheviorRelay: BehaviorRelay<Void> = BehaviorRelay(value: ())
    private let disposeBag: DisposeBag = DisposeBag()
    
    // MARK: -
    
    init(
        assetPairsRepo: AssetPairsRepo
        ) {
        
        self.assetPairsRepo = assetPairsRepo
        self.observeAssetPairsRepo()
        
        if self.assetPairsRepo.assetPairsValue.isEmpty {
            self.assetPairsRepo.updateAssetPairs()
        }
    }
    
    // MARK: - Public properties
    
    var rate: Observable<Void> {
        return self.rateEventBaheviorRelay.asObservable()
    }
    
    // MARK: - Public
    
    func rateForAmount(
        _ amount: Decimal,
        ofAsset asset: String,
        destinationAsset: String
        ) -> Decimal? {
        
        return amount * (self.rateFromAsset(
            asset,
            to: destinationAsset
            ) ?? 1)
    }
    
    // MARK: - Private
    
    private func observeAssetPairsRepo() {
        self.assetPairsRepo
            .observeAssetPairs()
            .subscribe(onNext: { [weak self] (_) in
                self?.rateEventBaheviorRelay.accept(())
            })
            .disposed(by: self.disposeBag)
    }
    
    private func rateFromAsset(
        _ asset: String,
        to destinationAsset: String
        ) -> Decimal? {
        
        if asset == destinationAsset {
            return 1
        }
        
        let pairs = self.assetPairsRepo.assetPairsValue
        let convertionAsset: String = "USD"
        
        let mainPair = pairs.first { (pair) -> Bool in
            return pair.base == asset && pair.quote == destinationAsset
        }
        let mainPairPrice: Decimal? = mainPair?.currentPrice
        
        let quotePair = pairs.first { (pair) -> Bool in
            return pair.base == destinationAsset && pair.quote == asset
        }
        let quotePairPrice: Decimal? = {
            if let price = quotePair?.currentPrice {
                return 1 / price
            }
            return nil
        }()
        
        let throughDefaultAssetPrice: Decimal? = {
            if destinationAsset == convertionAsset
                || asset == convertionAsset {
                return nil
            }
            let assetConvertionAssetRate = self.rateFromAsset(
                asset,
                to: convertionAsset
                ) ?? 1
            let convertionAssetAssetRate = self.rateFromAsset(
                convertionAsset,
                to: destinationAsset
                ) ?? 1
            return assetConvertionAssetRate * convertionAssetAssetRate
        }()
        
        return mainPairPrice ?? quotePairPrice ?? throughDefaultAssetPrice
    }
}
