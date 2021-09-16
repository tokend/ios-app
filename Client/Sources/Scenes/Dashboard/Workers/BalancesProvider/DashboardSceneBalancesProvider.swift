import Foundation
import RxCocoa
import RxSwift

extension DashboardScene {
    class BalancesProvider {
        
        // MARK: - Private properties
        
        private let balancesBehaviorRelay: BehaviorRelay<[DashboardScene.Model.Balance]> = .init(value: [])
        private let loadingStatusBehaviorRelay: BehaviorRelay<DashboardScene.Model.LoadingStatus> = .init(value: .loading)
        private let assetsRepo: AssetsRepo
        private let balancesRepo: BalancesRepo
        private let imagesUtility: ImagesUtility

        private let disposeBag: DisposeBag = .init()
        private var shouldObserveRepos: Bool = true
        
        // MARK: -
         
        init(
            assetsRepo: AssetsRepo,
            balancesRepo: BalancesRepo,
            imagesUtility: ImagesUtility
        ) {
            
            self.assetsRepo = assetsRepo
            self.balancesRepo = balancesRepo
            self.imagesUtility = imagesUtility
        }
    }
}

// MARK: - Private methods

private extension DashboardScene.BalancesProvider {
    
    func observeRepos() {
        if shouldObserveRepos {
            shouldObserveRepos = false
            observeBalancesList()
            observeReposLoadingStatus()
        }
    }
    
    func observeBalancesList() {
        Observable.combineLatest(
            balancesRepo.observeBalancesDetails(),
            assetsRepo.observeAssets()
        ).subscribe(onNext: { [weak self] (tuple) in
            
            guard let imagesUtility = self?.imagesUtility
            else {
                return
            }
            
            let balances: [BalancesRepo.BalanceState] = tuple.0
            let assets: [AssetsRepo.Asset] = tuple.1
            
            self?.balancesBehaviorRelay.accept(
                balances.mapToBalances(
                    assets: assets,
                    imagesUtility: imagesUtility
                ).sorted(by: { $0.available > $1.available })
            )
        })
        .disposed(by: disposeBag)
    }
    
    func observeReposLoadingStatus() {
        Observable.combineLatest(
            balancesRepo.observeLoadingStatus(),
            assetsRepo.observeLoadingStatus()
        ).subscribe(onNext: { [weak self] (tuple) in
            
            if tuple.0 == .loaded && tuple.1 == .loaded {
                self?.loadingStatusBehaviorRelay.accept(.loaded)
            } else {
                self?.loadingStatusBehaviorRelay.accept(.loading)
            }
        })
        .disposed(by: disposeBag)
    }
}

// MARK: - Mappers

private extension Array where Element == BalancesRepo.BalanceState {
    
    func mapToBalances(
        assets: [AssetsRepo.Asset],
        imagesUtility: ImagesUtility
    ) -> [DashboardScene.Model.Balance] {
        return self.compactMap { (balance) in
            return try? balance.mapToBalance(
                assets: assets,
                imagesUtility: imagesUtility
            )
        }
    }
}

private enum BalancesProviderMapperError: Swift.Error {
    case noBalance
    case noAsset
}

private extension BalancesRepo.BalanceState {
    func mapToBalance(
        assets: [AssetsRepo.Asset],
        imagesUtility: ImagesUtility
    ) throws -> DashboardScene.Model.Balance {
        
        switch self {
        
        case .creating:
            throw BalancesProviderMapperError.noBalance
            
        case .created(let balance):
            
            guard let asset = assets.first(where: { $0.id == balance.asset.id })
            else {
                throw BalancesProviderMapperError.noAsset
            }
            
            let avatar: TokenDUIImage?
            if let assetLogo = asset.details.logo {
                let logo: Document<UIImage> = .uploaded(
                    .init(
                        mimeType: assetLogo.mimeType ?? "",
                        name: "",
                        key: assetLogo.key
                    )
                )
                
                avatar = .init(
                    url: logo.imageUrl(imagesUtility: imagesUtility)
                )
            } else {
                avatar = nil
            }
            
            
            return .init(
                id: balance.id,
                name: asset.details.name ?? balance.asset.asset,
                code: balance.asset.id,
                avatar: avatar,
                available: balance.balance
            )
        }
    }
}

// MARK: - DashboardSceneBalancesProviderProtocol

extension DashboardScene.BalancesProvider: DashboardScene.BalancesProviderProtocol {
    var balances: [DashboardScene.Model.Balance] {
        return balancesBehaviorRelay.value
    }
    
    var loadingStatus: DashboardScene.Model.LoadingStatus {
        return loadingStatusBehaviorRelay.value
    }
    
    func observeBalances() -> Observable<[DashboardScene.Model.Balance]> {
        observeRepos()
        return balancesBehaviorRelay.asObservable()
    }
    
    func observeLoadingStatus() -> Observable<DashboardScene.Model.LoadingStatus> {
        observeRepos()
        return loadingStatusBehaviorRelay.asObservable()
    }
    
    func initiateReload() {
        // TODO: - Implement
    }
}
