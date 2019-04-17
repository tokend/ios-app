import Foundation
import TokenDWallet
import RxSwift

enum SendPaymentBalanceDetailsLoaderLoadingStatus {
    case loading
    case loaded
}
extension SendPaymentBalanceDetailsLoaderLoadingStatus {
    var responseValue: SendPayment.Event.LoadBalances.Response {
        switch self {
            
        case .loaded:
            return .loaded
            
        case .loading:
            return .loading
        }
    }
}

protocol SendPaymentsBalanceDetailsLoaderProtocol {
    func observeBalanceDetails() -> Observable<[SendPayment.Model.BalanceDetails]>
    func observeLoadingStatus() -> Observable<SendPaymentBalanceDetailsLoaderLoadingStatus>
    func observeErrors() -> Observable<Swift.Error>
    func loadBalanceDetails()
}

extension SendPayment {
    typealias BalanceDetailsLoader = SendPaymentsBalanceDetailsLoaderProtocol
}

extension SendPayment {
    class BalanceDetailsLoaderWorker {
        
        // MARK: - Private properties
        
        private let balancesRepo: BalancesRepo
        private let assetsRepo: AssetsRepo
        private let operation: SendPayment.Model.Operation
        
        // MARK: -
        
        init(
            balancesRepo: BalancesRepo,
            assetsRepo: AssetsRepo,
            operation: SendPayment.Model.Operation
            ) {
            
            self.balancesRepo = balancesRepo
            self.assetsRepo = assetsRepo
            self.operation = operation
        }
        
        // MARK: - Private
        
        private func filterWithdrawable(
            balances: [SendPayment.Model.BalanceDetails]
            ) -> [SendPayment.Model.BalanceDetails] {
            
            return balances.filter { [weak self] (balance) -> Bool in
                if let asset = self?.assetsRepo.assetsValue.first(where: { (asset) -> Bool in
                    asset.code == balance.asset
                }) {
                    return Int32(asset.policy) & AssetPolicy.withdrawable.rawValue == AssetPolicy.withdrawable.rawValue
                }
                return false
            }
        }
    }
}

// MARK: - BalanceDetailsLoader

extension SendPayment.BalanceDetailsLoaderWorker: SendPayment.BalanceDetailsLoader {
    func observeBalanceDetails() -> Observable<[SendPayment.Model.BalanceDetails]> {
        typealias BalanceDetails = SendPayment.Model.BalanceDetails
        
        return self.balancesRepo.observeBalancesDetails().map { (balanceDetails) -> [BalanceDetails] in
            let balances = balanceDetails.compactMap({ (balanceState) -> BalanceDetails? in
                switch balanceState {
                    
                case .created(let balance):
                    let balanceModel = BalanceDetails(
                        asset: balance.asset,
                        balance: balance.balance,
                        balanceId: balance.balanceId
                    )
                    return balanceModel
                    
                case .creating:
                    return nil
                }
            })
            
            switch self.operation {
                
            case .handleSend:
                return balances.filter({ (balance) -> Bool in
                    return balance.balance > 0
                })
                
            case .handleWithdraw:
                return self.filterWithdrawable(balances: balances)
            }
        }
    }
    
    func observeLoadingStatus() -> Observable<SendPaymentBalanceDetailsLoaderLoadingStatus> {
        return self.balancesRepo
            .observeLoadingStatus()
            .map { (status) -> SendPaymentBalanceDetailsLoaderLoadingStatus in
                return status.status
        }
    }
    
    func observeErrors() -> Observable<Swift.Error> {
        return self.balancesRepo.observeErrorStatus()
    }
    
    func loadBalanceDetails() {
        self.balancesRepo.reloadBalancesDetails()
    }
}

private extension BalancesRepo.LoadingStatus {
    var status: SendPaymentBalanceDetailsLoaderLoadingStatus {
        switch self {
        case .loading:
            return .loading
        case .loaded:
            return .loaded
        }
    }
}
