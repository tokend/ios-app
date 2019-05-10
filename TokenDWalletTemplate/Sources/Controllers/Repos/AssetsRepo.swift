import Foundation
import RxSwift
import RxCocoa
import TokenDSDK

public class AssetsRepo {
    
    public typealias Asset = TokenDSDK.Asset
    
    public enum LoadingStatus {
        case loading
        case loaded
    }
    
    // MARK: - Private properties
    
    private let api: TokenDSDK.API
    private let assets: BehaviorRelay<[Asset]> = BehaviorRelay(value: [])
    private let loadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
    private let errorStatus: PublishRelay<Swift.Error> = PublishRelay()
    
    private let disposeBag = DisposeBag()
    
    private var shouldInitiateLoad: Bool = true
    
    // MARK: - Public properties
    
    public var assetsValue: [Asset] {
        return self.assets.value
    }
    
    public var loadingStatusValue: LoadingStatus {
        return self.loadingStatus.value
    }
    
    // MARK: -
    
    public init(
        api: TokenDSDK.API
        ) {
        
        self.api = api
        self.observeRepoErrorStatus()
    }
    
    // MARK: - Private
    
    private func observeRepoErrorStatus() {
        self.errorStatus
            .asObservable()
            .subscribe(onNext: { [weak self] (_) in
                self?.shouldInitiateLoad = true
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Public
    
    public func observeAssets() -> Observable<[Asset]> {
        if self.shouldInitiateLoad {
            self.shouldInitiateLoad = false
            self.reloadAssets()
        }
        return self.assets.asObservable()
    }
    
    public func observeAsset(code: String) -> Observable<Asset?> {
        if self.shouldInitiateLoad {
            self.shouldInitiateLoad = false
            self.reloadAssets()
        }
        return self.assets.map { $0.first { $0.code == code } }.asObservable()
    }
    
    public func observeLoadingStatus() -> Observable<LoadingStatus> {
        return self.loadingStatus.asObservable()
    }
    
    public func observeErrorStatus() -> Observable<Swift.Error> {
        return self.errorStatus.asObservable()
    }
    
    public func reloadAssets() {
        guard self.loadingStatusValue != .loading else { return }
        self.loadingStatus.accept(.loading)
        self.api.assetsApi.requestAssets { [weak self] (result) in
            switch result {
            case .failure(let errors):
                self?.errorStatus.accept(errors)
            case .success(let assets):
                self?.assets.accept(assets)
            }
            self?.loadingStatus.accept(.loaded)
        }
    }
}
