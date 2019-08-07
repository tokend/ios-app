import Foundation
import RxSwift
import RxCocoa

extension BalancesFetcher: DashboardPaymentsPlugIn.BalancesFetcherProtocol {
    
    var paymentsPreviewBalances: [PaymentsPreviewBalance] {
        return self.convertBalancesToPaymentsPreviewBalances(self.balancesBehaviorRelay.value)
    }
    
    func observePaymentsPreviewBalances() -> Observable<[PaymentsPreviewBalance]> {
        return self.balancesBehaviorRelay
            .asObservable()
            .map({ [weak self] (balances) -> [PaymentsPreviewBalance] in
                return self?.convertBalancesToPaymentsPreviewBalances(balances) ?? []
            })
    }
    
    typealias LoadingStatus = DashboardPaymentsPlugInBalancesFetcherProtocol.LoadingStatus
    
    func observePaymentsPreviewBalancesLoadingStatus() -> Observable<LoadingStatus> {
        return self.balancesLoadingStatus
            .map({ (status) -> LoadingStatus in
                return status.status
            })
    }
    
    func observePaymentsPreviewBalancesErrorStatus() -> Observable<Error> {
        return self.balancesErrorStatus.asObservable()
    }
    
    func refreshPaymentsPreviewBalances() {
        self.refreshBalances()
    }
    
    private func convertBalancesToPaymentsPreviewBalances(_ balances: [Balance]) -> [PaymentsPreviewBalance] {
        return balances.map { (balance) in
            return balance.balance
        }
    }
}

private extension BalancesRepo.BalanceState {
    typealias Balance = DashboardPaymentsPlugIn.Model.Balance
    typealias Amount = DashboardPaymentsPlugIn.Model.Amount
    
    var balance: Balance {
        
        switch self {
            
        case .creating(let asset):
            return Balance(
                balance: Amount(value: 0, asset: asset),
                balanceId: nil
            )
            
        case .created(let balance):
            return Balance(
                balance: Amount(value: balance.balance, asset: balance.asset),
                balanceId: balance.balanceId
            )
        }
    }
}

private extension BalancesRepo.LoadingStatus {
    var status: DashboardPaymentsPlugInBalancesFetcherProtocol.LoadingStatus {
        switch self {
        case .loading:
            return .loading
        case .loaded:
            return .loaded
        }
    }
}
