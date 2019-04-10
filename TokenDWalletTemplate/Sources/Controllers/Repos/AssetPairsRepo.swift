import Foundation
import RxSwift
import RxCocoa
import TokenDSDK

public class AssetPairsRepo {
    
    public typealias AssetPair = TokenDSDK.AssetPair
    
    public enum LoadingStatus {
        case loading
        case loaded
    }
    
    // MARK: - Private properties
    
    private let api: TokenDSDK.AssetPairsApi
    private let assetPairs: BehaviorRelay<[AssetPair]> = BehaviorRelay(value: [])
    private let loadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
    private let errorsStatus: PublishRelay<Swift.Error> = PublishRelay()
    
    // MARK: - Public properties
    
    public var assetPairsValue: [AssetPair] {
        return self.assetPairs.value
    }
    
    public var loadingStatusValue: LoadingStatus {
        return self.loadingStatus.value
    }
    
    // MARK: -
    
    public init(
        api: TokenDSDK.AssetPairsApi
        ) {
        
        self.api = api
    }
    
    // MARK: - Public
    
    public func observeAssetPairs() -> Observable<[AssetPair]> {
        return self.assetPairs.asObservable()
    }
    
    public func observeLoadingStatus() -> Observable<LoadingStatus> {
        return self.loadingStatus.asObservable()
    }
    
    public func observeErrorStatus() -> Observable<Swift.Error> {
        return self.errorsStatus.asObservable()
    }
    
    public func updateAssetPairs() {
        guard self.loadingStatusValue != .loading else { return }
        self.loadingStatus.accept(.loading)
        self.api.requestAssetPairs { [weak self] (result) in
            switch result {
            case .failure(let errors):
                self?.errorsStatus.accept(errors)
            case .success(let assetPairs):
                self?.assetPairs.accept(assetPairs)
            }
            self?.loadingStatus.accept(.loaded)
        }
    }
}
