import Foundation
import RxCocoa
import RxSwift

protocol BalanceHeaderBalanceFetcherProtocol {
    func observeBalance() -> Observable<BalanceHeader.Model.Balance?>
}

extension BalanceHeader {
    typealias BalanceFetcherProtocol = BalanceHeaderBalanceFetcherProtocol
    
    class BalancesFetcher {
        
        // MARK: - Private properties
        
        private let balancesRepo: BalancesRepo
        private let assetsRepo: AssetsRepo
        
        private let balance: BehaviorRelay<BalanceHeader.Model.Balance?> = BehaviorRelay(value: nil)
        private let imageUtility: ImagesUtility
        
        private var balances: [BalancesRepo.BalanceDetails] = []
        private var assets: [AssetsRepo.Asset] = []
        private let disposeBag: DisposeBag = DisposeBag()
        
        private let balanceId: String
        private let rateAsset: String = "USD"
        
        // MARK: -
        
        init(
            balancesRepo: BalancesRepo,
            assetsRepo: AssetsRepo,
            imageUtility: ImagesUtility,
            balanceId: String
            ) {
            
            self.balancesRepo = balancesRepo
            self.assetsRepo = assetsRepo
            self.imageUtility = imageUtility
            self.balanceId = balanceId
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
                    self?.updateBalance()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeAssetsRepo() {
            self.assetsRepo
                .observeAssets()
                .subscribe(onNext: { [weak self] (assets) in
                    self?.assets = assets
                    self?.updateBalance()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func updateBalance() {
            guard let balance = self.balances.first(where: { (balance) -> Bool in
                return balance.balanceId == self.balanceId
            }) else {
                return
            }
            
            var iconUrl: URL?
            if let asset = self.assets.first(where: { (asset) -> Bool in
                return asset.code == balance.asset
            }), let key = asset.defaultDetails?.logo?.key {
                
                let imageKey = ImagesUtility.ImageKey.key(key)
                iconUrl = self.imageUtility.getImageURL(imageKey)
            }
            
            let amount = BalanceHeader.Model.Amount(
                value: balance.balance,
                asset: balance.asset
            )
            let convertedBalance = BalanceHeader.Model.Amount(
                value: balance.convertedBalance,
                asset: self.rateAsset
            )
            let updatedBalance = Model.Balance(
                balance: amount,
                iconUrl: iconUrl,
                convertedBalance: convertedBalance
            )
            self.balance.accept(updatedBalance)
        }
    }
}

extension BalanceHeader.BalancesFetcher: BalanceHeader.BalanceFetcherProtocol {
    
    public func observeBalance() -> Observable<BalanceHeader.Model.Balance?> {
        self.observeAssetsRepo()
        self.observeBalancesRepo()
        
        return self.balance.asObservable()
    }
}
