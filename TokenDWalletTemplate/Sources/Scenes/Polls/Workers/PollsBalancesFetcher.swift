import Foundation
import RxCocoa
import RxSwift

public protocol PollsAssetsFetcherProtocol {
    func observeAssets() -> Observable<[Polls.Model.Asset]>
    func observeLoadingStatus() -> Observable<Polls.Model.LoadingStatus>
}

extension Polls {
    public typealias AssetsFetcherProtocol = PollsAssetsFetcherProtocol
    
    class AssetsFetcher {
        
        // MARK: - Private properties
        
        private let assetsRepo: AssetsRepo
        
        private let assetsRelay: BehaviorRelay<[Model.Asset]> = BehaviorRelay(value: [])
        private let loadingStatus: BehaviorRelay<Model.LoadingStatus> = BehaviorRelay(value: .loaded)
        private var assets: [AssetsRepo.Asset] = []
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: -
        
        init(assetsRepo: AssetsRepo) {
            self.assetsRepo = assetsRepo
        }
        
        // MARK: - Private
        
        private func observeAssetsRepo() {
            self.assetsRepo
                .observeAssets()
                .subscribe(onNext: { [weak self] (assets) in
                    self?.assets = assets
                    self?.updateAssets()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func updateAssets() {
            let assets = self.assets.map { (asset) -> Model.Asset in
                return Model.Asset(
                    code: asset.code,
                    ownerAccountId: asset.owner
                )}
            self.assetsRelay.accept(assets)
        }
    }
}

extension Polls.AssetsFetcher: Polls.AssetsFetcherProtocol {
    
    public func observeAssets() -> Observable<[Polls.Model.Asset]> {
        self.observeAssetsRepo()
        return self.assetsRelay.asObservable()
    }
    
    public func observeLoadingStatus() -> Observable<Polls.Model.LoadingStatus> {
        self.assetsRepo
            .observeLoadingStatus()
            .subscribe(onNext: { [weak self] (status) in
                switch status {
                case .loaded:
                    self?.loadingStatus.accept(.loaded)
                    
                case .loading:
                    self?.loadingStatus.accept(.loading)
                }
            })
            .disposed(by: self.disposeBag)
        
        return self.loadingStatus.asObservable()
    }
}
