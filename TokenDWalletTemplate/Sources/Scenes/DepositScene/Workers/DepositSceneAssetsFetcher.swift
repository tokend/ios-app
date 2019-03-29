import Foundation
import RxSwift
import RxCocoa
import TokenDSDK

extension DepositScene {
    class AssetsFetcher: AssetsFetcherProtocol {
        
        // MARK: - Private properties
        
        private let assetsRepo: AssetsRepo
        private let balancesRepo: BalancesRepo
        private let accountRepo: AccountRepo
        private let externalSystemBalancesManager: ExternalSystemBalancesManager
        
        private let depositableAssetsBehaviorRelay: BehaviorRelay<[Model.Asset]> = BehaviorRelay(value: [])
        private let depositableAssetLoadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
        private let depositableAssetErrorStatus: PublishRelay<Swift.Error> = PublishRelay()
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: - Public properties
        
        var assets: [AssetsFetcherProtocol.Asset] {
            return self.depositableAssetsBehaviorRelay.value
        }
        
        // MARK: -
        
        init(
            assetsRepo: AssetsRepo,
            balancesRepo: BalancesRepo,
            accountRepo: AccountRepo,
            externalSystemBalancesManager: ExternalSystemBalancesManager
            ) {
            
            self.assetsRepo = assetsRepo
            self.balancesRepo = balancesRepo
            self.accountRepo = accountRepo
            self.externalSystemBalancesManager = externalSystemBalancesManager
            
            self.observeAssetsRepo()
            self.observeAssetsRepoLoadingStatus()
            self.observeAssetsRepoErrorStatus()
            self.observeAccount()
            self.observeBalances()
            self.observeBalancesErrors()
            self.observeBindingStatuses()
            self.observeBindingErrors()
        }
        
        // MARK: - Private
        
        private func observeAssetsRepo() {
            self.assetsRepo
                .observeAssets()
                .subscribe(onNext: { [weak self] (_) in
                    self?.updateDepositableAssets()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeAssetsRepoLoadingStatus() {
            self.assetsRepo
                .observeLoadingStatus()
                .subscribe(onNext: { [weak self] (status) in
                    self?.depositableAssetLoadingStatus.accept(status.status)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeAssetsRepoErrorStatus() {
            self.assetsRepo
                .observeErrorStatus()
                .subscribe(onNext: { [weak self] (error) in
                    self?.depositableAssetErrorStatus.accept(error)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeAccount() {
            self.accountRepo
                .observeAccount()
                .subscribe(onNext: { [weak self] (_) in
                    self?.updateDepositableAssets()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeBalances() {
            self.balancesRepo
                .observeBalancesDetails()
                .subscribe(onNext: { (_) in
                    self.updateDepositableAssets()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeBalancesErrors() {
            self.balancesRepo
                .observeErrorStatus()
                .subscribe(onNext: { (error) in
                    self.depositableAssetErrorStatus.accept(error)
                })
            .disposed(by: self.disposeBag)
        }
        
        private func observeBindingStatuses() {
            self.externalSystemBalancesManager
                .observeBindingStatuses()
                .subscribe { [weak self] (_) in
                    self?.updateDepositableAssets()
                }
                .disposed(by: self.disposeBag)
        }
        
        private func observeBindingErrors() {
            self.externalSystemBalancesManager
                .observeBindingStatusesErrors()
                .subscribe(onNext: { (error) in
                    self.depositableAssetErrorStatus.accept(error)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func updateDepositableAssets() {
            guard let account = self.accountRepo.accountValue else {
                self.accountRepo.updateAccount({ (_) in })
                self.depositableAssetsBehaviorRelay.accept([])
                return
            }
            let assets = self.assetsRepo.assetsValue
            let balances = self.balancesRepo.balancesDetailsValue
            
            let depositableBalances: [Model.Asset] = assets.compactMap { (asset) -> Model.Asset? in
                guard let externalSystemType = asset.defaultDetails?.externalSystemType else {
                    return nil
                }
                let optionalExternalSystemAccount = account.externalSystemAccounts.first(where: { (account) -> Bool in
                    return account.type.value == externalSystemType
                })
                
                let address: String? = {
                    guard let account = optionalExternalSystemAccount else {
                        return nil
                    }
                    guard let expirationDate = account.expiresAt else {
                        return account.data
                    }
                    guard Date() < expirationDate else {
                        return nil
                    }
                    
                    return account.data
                }()
                
                let balance = balances.first(where: { (state) -> Bool in
                    return state.asset == asset.code
                })
                
                let manager = self.externalSystemBalancesManager
                let bindingStatus = manager.bindingStatusValueForAccount(externalSystemType)
                let hasExternalAccount = optionalExternalSystemAccount != nil
                let hasExternalAccountExpiration = optionalExternalSystemAccount?.expiresAt != nil
                let isRenewable = (hasExternalAccount && hasExternalAccountExpiration) || !hasExternalAccount
                
                let isRenewing: Bool
                switch balance {
                case .none:
                    isRenewing = false
                case .some(let value):
                    switch value {
                    case .created:
                        isRenewing = bindingStatus == .binding
                    case .creating:
                        isRenewing = true
                    }
                }
                
                return Model.Asset(
                    id: asset.identifier,
                    address: address,
                    asset: asset.code,
                    expirationDate: optionalExternalSystemAccount?.expiresAt,
                    isRenewable: isRenewable,
                    isRenewing: isRenewing,
                    externalSystemType: externalSystemType
                )
            }
            self.depositableAssetsBehaviorRelay.accept(depositableBalances)
        }
        
        // MARK: - Public
        
        func observeAssets() -> Observable<[AssetsFetcherProtocol.Asset]> {
            return self.depositableAssetsBehaviorRelay.asObservable()
        }
        
        func observeAssetsLoadingStatus() -> Observable<DepositSceneAssetsFetcherProtocol.LoadingStatus> {
            return self.depositableAssetLoadingStatus.asObservable()
        }
        
        func observeAssetsErrorStatus() -> Observable<Error> {
            return self.depositableAssetErrorStatus.asObservable()
        }
        
        func assetForId(_ id: AssetID) -> AssetsFetcherProtocol.Asset? {
            return self.depositableAssetsBehaviorRelay.value.first(where: { (asset) -> Bool in
                return asset.id == id
            })
        }
        
        func refreshAssets() {
            self.assetsRepo.reloadAssets()
        }
    }
}

private extension AssetsRepo.LoadingStatus {
    var status: DepositSceneAssetsFetcherProtocol.LoadingStatus {
        switch self {
        case .loading:
            return .loading
        case .loaded:
            return .loaded
        }
    }
}
