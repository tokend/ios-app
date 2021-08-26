import Foundation
import RxSwift
import RxCocoa

extension BalanceDetailsScene {
    
    class BalanceProvider {
        
        // MARK: Private properties
        
        private let balanceBehaviorRelay: BehaviorRelay<BalanceDetailsScene.Model.Balance?> = .init(value: nil)
        private let loadingStatusBehaviorRelay: BehaviorRelay<BalanceDetailsScene.Model.LoadingStatus> = .init(value: .loading)
        
        private let assetsRepo: AssetsRepo
        private let balancesRepo: BalancesRepo
        private let imagesUtility: ImagesUtility
        
        private let balanceId: String
        
        private let disposeBag: DisposeBag = .init()
        private var shouldObserveRepos: Bool = true
        
        // MARK:
        
        init(
            balanceId: String,
            assetsRepo: AssetsRepo,
            balancesRepo: BalancesRepo,
            imagesUtility: ImagesUtility
        ) {
            
            self.balanceId = balanceId
            self.assetsRepo = assetsRepo
            self.balancesRepo = balancesRepo
            self.imagesUtility = imagesUtility
        }
    }
}

// MARK: Private methods

private extension BalanceDetailsScene.BalanceProvider {
    
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
            
            guard let balanceId = self?.balanceId,
                  let imagesUtility = self?.imagesUtility
            else {
                return
            }
            
            let balances: [BalancesRepo.BalanceState] = tuple.0
            let assets: [AssetsRepo.Asset] = tuple.1
            
            self?.balanceBehaviorRelay.accept(
                balances.findBalance(
                    with: balanceId,
                    assets: assets,
                    imagesUtility: imagesUtility
                )
            )
        })
        .disposed(by: disposeBag)
    }
    
    func observeReposLoadingStatus() {
        assetsRepo.observeLoadingStatus()
            .subscribe(onNext: { [weak self] (status) in
                
                switch status {
                
                case .loaded:
                    self?.loadingStatusBehaviorRelay.accept(.loaded)

                case .loading:
                    self?.loadingStatusBehaviorRelay.accept(.loading)
                }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: Mappers

private extension Array where Element == BalancesRepo.BalanceState {
    
    func findBalance(
        with balanceId: String,
        assets: [AssetsRepo.Asset],
        imagesUtility: ImagesUtility
    ) -> BalanceDetailsScene.Model.Balance? {
        
        return try? first(
            where: { (balanceState) in
                switch balanceState {
                
                case .creating:
                    return false
                    
                case .created(let balance):
                    return balance.id == balanceId
                }
            }
        )?
        .mapToBalance(
            assets: assets,
            imagesUtility: imagesUtility
        )
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
    ) throws -> BalanceDetailsScene.Model.Balance {
        
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
                icon: avatar,
                name: asset.details.name ?? balance.asset.asset,
                balance: balance.balance,
                asset: balance.asset.id,
                rate: 1,
                rateAsset: "USD"
            )
        }
    }
}

// MARK: BalanceDetailsScene.BalanceProviderProvider

extension BalanceDetailsScene.BalanceProvider: BalanceDetailsScene.BalanceProviderProtocol {
    
    var balance: BalanceDetailsScene.Model.Balance? {
        observeRepos()
        return balanceBehaviorRelay.value
    }
    
    var loadingStatus: BalanceDetailsScene.Model.LoadingStatus {
        observeRepos()
        return loadingStatusBehaviorRelay.value
    }
    
    func observeBalance() -> Observable<BalanceDetailsScene.Model.Balance?> {
        observeRepos()
        return balanceBehaviorRelay.asObservable()
    }
    
    func observeLoadingStatus() -> Observable<BalanceDetailsScene.Model.LoadingStatus> {
        observeRepos()
        return loadingStatusBehaviorRelay.asObservable()
    }
    
    func reloadBalance() {
        balancesRepo.reloadBalances()
    }
}
