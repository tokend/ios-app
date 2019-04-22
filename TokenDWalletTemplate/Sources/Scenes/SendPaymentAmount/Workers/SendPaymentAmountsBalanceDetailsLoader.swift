import Foundation
import TokenDWallet
import RxSwift

enum SendPaymentAmountBalanceDetailsLoaderLoadingStatus {
    case loading
    case loaded
}
extension SendPaymentAmountBalanceDetailsLoaderLoadingStatus {
    var responseValue: SendPaymentAmount.Event.LoadBalances.Response {
        switch self {
            
        case .loaded:
            return .loaded
            
        case .loading:
            return .loading
        }
    }
}

protocol SendPaymentsAmountBalanceDetailsLoaderProtocol {
    func observeBalanceDetails() -> Observable<[SendPaymentAmount.Model.BalanceDetails]>
    func observeLoadingStatus() -> Observable<SendPaymentAmountBalanceDetailsLoaderLoadingStatus>
    func observeErrors() -> Observable<Swift.Error>
    func loadBalanceDetails()
}

extension SendPaymentAmount {
    typealias BalanceDetailsLoader = SendPaymentsAmountBalanceDetailsLoaderProtocol
}

extension SendPaymentAmount {
    class BalanceDetailsLoaderWorker {
        
        // MARK: - Private properties
        
        private let balancesRepo: BalancesRepo
        private let assetsRepo: AssetsRepo
        private let operation: SendPaymentAmount.Model.Operation
        
        // MARK: -
        
        init(
            balancesRepo: BalancesRepo,
            assetsRepo: AssetsRepo,
            operation: SendPaymentAmount.Model.Operation
            ) {
            
            self.balancesRepo = balancesRepo
            self.assetsRepo = assetsRepo
            self.operation = operation
        }
        
        // MARK: - Private
        
        private func filterWithdrawable(
            balances: [SendPaymentAmount.Model.BalanceDetails]
            ) -> [SendPaymentAmount.Model.BalanceDetails] {
            
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

extension SendPaymentAmount.BalanceDetailsLoaderWorker: SendPaymentAmount.BalanceDetailsLoader {
    func observeBalanceDetails() -> Observable<[SendPaymentAmount.Model.BalanceDetails]> {
        typealias BalanceDetails = SendPaymentAmount.Model.BalanceDetails
        
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
    
    func observeLoadingStatus() -> Observable<SendPaymentAmountBalanceDetailsLoaderLoadingStatus> {
        return self.balancesRepo
            .observeLoadingStatus()
            .map { (status) -> SendPaymentAmountBalanceDetailsLoaderLoadingStatus in
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
    var status: SendPaymentAmountBalanceDetailsLoaderLoadingStatus {
        switch self {
        case .loading:
            return .loading
        case .loaded:
            return .loaded
        }
    }
}
