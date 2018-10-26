import Foundation
import RxSwift
import RxCocoa

class BalanceBinder: BalanceBinderProtocol {
    
    // MARK: - Private properties
    
    private let balancesRepo: BalancesRepo
    private let accountRepo: AccountRepo
    private let externalSystemBalancesManager: ExternalSystemBalancesManager
    
    private var disposables: [String: Disposable] = [:]
    private var isWaiting: [String: Bool] = [:]
    
    // MARK: -
    
    init(
        balancesRepo: BalancesRepo,
        accountRepo: AccountRepo,
        externalSystemBalancesManager: ExternalSystemBalancesManager
        ) {
        
        self.balancesRepo = balancesRepo
        self.accountRepo = accountRepo
        self.externalSystemBalancesManager = externalSystemBalancesManager
    }
    
    // MARK: - Private
    
    private func waitUntilBalanceCreatedAndBind(
        _ asset: String,
        toAccount externalType: Int32,
        completion: @escaping (BalanceBinderBindBalanceResult) -> Void
        ) {
        
        self.isWaiting[asset] = true
        self.disposables[asset]?.dispose()
        self.disposables[asset] = self.balancesRepo
            .observeBalancesDetails()
            .subscribe(onNext: { [weak self] (details) in
                guard self?.isWaiting[asset] == true else {
                    self?.disposables[asset]?.dispose()
                    return
                }
                
                var creating: Bool = false
                let contains: Bool = details.contains(where: { (state) -> Bool in
                    switch state {
                    case .created(let details):
                        return details.asset == asset
                    case .creating(let detailsAsset):
                        if detailsAsset == asset {
                            creating = true
                            return true
                        }
                        return false
                    }
                })
                
                if !creating {
                    if contains {
                        self?.bind(
                            toAccount: externalType,
                            completion: completion
                        )
                    } else {
                        completion(.failed)
                    }
                    self?.isWaiting[asset] = false
                }
            })
    }
    
    private func bind(
        toAccount externalType: Int32,
        completion: @escaping (BalanceBinderBindBalanceResult) -> Void
        ) {
        
        self.externalSystemBalancesManager.bindBalanceWithAccount(
            externalType
        ) { (result) in
            switch result {
            case .succeeded:
                completion(.succeeded)
            case .failed:
                completion(.failed)
            }
        }
    }
    
    // MARK: - Public
    
    func bindBalance(
        _ asset: String,
        toAccount externalType: Int32,
        completion: @escaping (BalanceBinderBindBalanceResult) -> Void
        ) {
        
        var creating: Bool = false
        let contains: Bool = self.balancesRepo.balancesDetailsValue.contains(where: { [weak self] (state) -> Bool in
            switch state {
            case .created(let details):
                return details.asset == asset
            case .creating(let detailsAsset):
                if detailsAsset == asset {
                    creating = true
                    self?.waitUntilBalanceCreatedAndBind(
                        asset,
                        toAccount: externalType,
                        completion: completion
                    )
                }
                return false
            }
        })
        
        if creating {
            self.waitUntilBalanceCreatedAndBind(
                asset,
                toAccount: externalType,
                completion: completion
            )
        } else if contains {
            self.bind(
                toAccount: externalType,
                completion: completion
            )
        } else {
            self.balancesRepo.createBalanceForAsset(asset) { (_) in }
            self.waitUntilBalanceCreatedAndBind(
                asset,
                toAccount: externalType,
                completion: completion
            )
        }
    }
}
