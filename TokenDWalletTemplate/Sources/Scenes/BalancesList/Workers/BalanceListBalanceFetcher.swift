import Foundation
import RxCocoa
import RxSwift

protocol BalanceListBalanceFetcherProtocol {
    func observeBalances() -> Observable<[BalancesList.Model.Balance]>
    func observeLoadingStatus() -> Observable<BalancesList.Model.LoadingStatus>
}

extension BalancesList {
    typealias BalancesFetcherProtocol = BalanceListBalanceFetcherProtocol
    
    class BalancesFetcher {
        
        // MARK: - Private properties
        
        private let balancesRepo: BalancesRepo
        private let assetsRepo: AssetsRepo
        
        private let imageUtility: ImagesUtility
        private let balancesRelay: BehaviorRelay<[Model.Balance]> = BehaviorRelay(value: [])
        private let loadingStatus: BehaviorRelay<Model.LoadingStatus> = BehaviorRelay(value: .loaded)
        
        private var balances: [BalancesRepo.BalanceDetails] = []
        private var assets: [AssetsRepo.Asset] = []
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: -
        
        init(
            balancesRepo: BalancesRepo,
            assetsRepo: AssetsRepo,
            imageUtility: ImagesUtility
            ) {
            
            self.balancesRepo = balancesRepo
            self.assetsRepo = assetsRepo
            self.imageUtility = imageUtility
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
            let updatedBalances = self.balances.map { (details) -> Model.Balance in
                var iconUrl: URL?
                var assetName: String?
                if let asset = self.assets.first(where: { (asset) -> Bool in
                    return details.asset == asset.code
                }) {
                    if let name = asset.defaultDetails?.name {
                        assetName = name
                    }
                    if let key = asset.defaultDetails?.logo?.key {
                        let imageKey = ImagesUtility.ImageKey.key(key)
                        iconUrl = self.imageUtility.getImageURL(imageKey)
                    }
                }
                
                return Model.Balance(
                    code: details.asset,
                    assetName: assetName ?? "",
                    iconUrl: iconUrl,
                    balance: details.balance,
                    balanceId: details.balanceId,
                    convertedBalance: details.convertedBalance,
                    cellIdentifier: .balances
                )}
                .sorted(by: { (left, right) -> Bool in
                    return left.convertedBalance > right.convertedBalance
                })
            
            self.balancesRelay.accept(updatedBalances)
        }
    }
}

extension BalancesList.BalancesFetcher: BalancesList.BalancesFetcherProtocol {
    
    func observeBalances() -> Observable<[BalancesList.Model.Balance]> {
        self.observeAssetsRepo()
        self.observeBalancesRepo()
        
        return self.balancesRelay.asObservable()
    }
    
    func observeLoadingStatus() -> Observable<BalancesList.Model.LoadingStatus> {
        self.balancesRepo
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
