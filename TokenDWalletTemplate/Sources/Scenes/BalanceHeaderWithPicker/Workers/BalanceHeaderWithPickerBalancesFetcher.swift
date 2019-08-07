import Foundation
import RxSwift
import RxCocoa
import TokenDSDK

extension BalancesFetcher: BalanceHeaderWithPicker.BalancesFetcherProtocol {
    var headerBalances: [HeaderBalance] {
        return self.convertBalancesToHeaderBalances(self.balancesBehaviorRelay.value)
    }
    
    func observeHeaderBalances() -> Observable<[HeaderBalance]> {
        return self.balancesBehaviorRelay
            .asObservable()
            .map({ [weak self] (balances) -> [HeaderBalance] in
                return self?.convertBalancesToHeaderBalances(balances) ?? []
            })
    }
    
    private func convertBalancesToHeaderBalances(_ balances: [Balance]) -> [HeaderBalance] {
        return balances.map { (balance) in
            return balance.balance
        }
    }
}

private extension BalancesRepo.BalanceState {
    typealias Balance = BalanceHeaderWithPicker.Model.Balance
    typealias Amount = BalanceHeaderWithPicker.Model.Amount
    
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
