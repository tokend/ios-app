import Foundation
import RxCocoa
import RxSwift

protocol BalancePickerBalancesFetcherProtocol {
    func observeBalances() -> Observable<[BalancePicker.Model.Balance]>
}

extension BalancePicker {
    typealias BalancesFetcherProtocol = BalancePickerBalancesFetcherProtocol
    
    class BalancesFetcher {
        
        // MARK: - Private properties
        
        private let balancesRepo: BalancesRepo
        private let assetsRepo: AssetsRepo
        private let imagesUtility: ImagesUtility
        private let targetAssets: [String]
        
        private let balancesRelay: BehaviorRelay<[Model.Balance]> = BehaviorRelay(value: [])
        
        private var balances: [BalancesRepo.BalanceDetails] = []
        private var assets: [AssetsRepo.Asset] = []
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: -
        
        init(
            balancesRepo: BalancesRepo,
            assetsRepo: AssetsRepo,
            imagesUtility: ImagesUtility,
            targetAssets: [String]
            ) {
            
            self.balancesRepo = balancesRepo
            self.assetsRepo = assetsRepo
            self.imagesUtility = imagesUtility
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
                    self?.updateBalances()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeAssetsRepo() {
            self.assetsRepo
                .observeAssets()
                .subscribe(onNext: { [weak self] (assets) in
                    self?.assets = assets
                    self?.updateBalances()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func updateBalances() {
            var balances: [Model.Balance] = []
            
            self.balances.forEach { (balance) in
                if let asset = self.assets.first(where: { (asset) -> Bool in
                    return asset.code == balance.asset
                        && self.targetAssets.contains(asset.code)
                        && balance.balance > 0
                }) {
                    let balance = Model.BalanceDetails(
                        amount: balance.balance,
                        balanceId: balance.balanceId
                    )
                    var iconUrl: URL?
                    if let key = asset.defaultDetails?.logo?.key {
                        let imageKey = ImagesUtility.ImageKey.key(key)
                        iconUrl = self.imagesUtility.getImageURL(imageKey)
                    }
                    let balanceModel = Model.Balance(
                        assetCode: asset.code,
                        iconUrl: iconUrl,
                        details: balance
                    )
                    balances.append(balanceModel)
                }
            }
            self.balancesRelay.accept(balances)
        }
    }
}

extension BalancePicker.BalancesFetcher: BalancePicker.BalancesFetcherProtocol {
    
    func observeBalances() -> Observable<[BalancePicker.Model.Balance]> {
        self.observeBalancesRepo()
        self.observeAssetsRepo()
        return self.balancesRelay.asObservable()
    }
}
