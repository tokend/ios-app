import Foundation
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
        
        // MARK: -
        
        init(balancesRepo: BalancesRepo) {
            self.balancesRepo = balancesRepo
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
            return balances
        }
    }
    
    func observeLoadingStatus() -> Observable<SendPaymentBalanceDetailsLoaderLoadingStatus> {
        return self.balancesRepo
            .observeLoadingStatus()
            .map { (status) -> SendPaymentBalanceDetailsLoaderLoadingStatus in
                return status.status
        }
    }
    
    func observeErrors() -> Observable<Error> {
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
