import Foundation
import RxCocoa
import RxSwift

protocol AssetPickerAssetsFetcherProtocol {
    func observeAssets() -> Observable<[AssetPicker.Model.Asset]>
}

extension AssetPicker {
    typealias AssetsFetcherProtocol = AssetPickerAssetsFetcherProtocol
    
    class AssetsFetcher {
        
        // MARK: - Private properties
        
        private let balancesRepo: BalancesRepo
        private let assetsRepo: AssetsRepo
        private let targetAssets: [String]
        
        private let assetsRelay: BehaviorRelay<[Model.Asset]> = BehaviorRelay(value: [])
        
        private var balances: [BalancesRepo.BalanceDetails] = []
        private var assets: [AssetsRepo.Asset] = []
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: -
        
        init(
            balancesRepo: BalancesRepo,
            assetsRepo: AssetsRepo,
            targetAssets: [String]
            ) {
            
            self.balancesRepo = balancesRepo
            self.assetsRepo = assetsRepo
            self.targetAssets = targetAssets
        }
        
        // MARK: - Private
        
        private func observeBalancesRepo() {
            self.balancesRepo
                .observeBalancesDetails()
                .subscribe(onNext: { [weak self] (states) in
                    self?.balances = states.compactMap({ (state) -> BalancesRepo.BalanceDetails? in
                        switch state {
                            
                        case .created(let balance):
                            return balance
                            
                        case .creating:
                            return nil
                        }
                    })
                    self?.updateAssets()
                })
                .disposed(by: self.disposeBag)
        }
        
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
            var assets: [Model.Asset] = []
            
            self.balances.forEach { (balance) in
                if let asset = self.assets.first(where: { (asset) -> Bool in
                    return asset.code == balance.asset && self.targetAssets.contains(asset.code)
                }) {
                    let balance = Model.Balance(
                        amount: balance.balance,
                        balanceId: balance.balanceId
                    )
                    let assetModel = Model.Asset(
                        code: asset.code,
                        balance: balance
                    )
                    assets.append(assetModel)
                }
            }
            self.assetsRelay.accept(assets)
        }
    }
}

extension AssetPicker.AssetsFetcher: AssetPicker.AssetsFetcherProtocol {
    
    func observeAssets() -> Observable<[AssetPicker.Model.Asset]> {
        self.observeBalancesRepo()
        self.observeAssetsRepo()
        return self.assetsRelay.asObservable()
    }
}
