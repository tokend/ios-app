import Foundation

enum SaleInvestBalanceCreateResult {
    case failure
    case success(SaleInvest.Model.BalanceDetails)
}
protocol SaleInvestBalanceCreatorProtocol {
    func createBalance(
        asset: String,
        completion: @escaping((SaleInvestBalanceCreateResult) -> Void)
    )
}

extension SaleInvest {
    typealias InvestBalanceCreatorProtocol = SaleInvestBalanceCreatorProtocol
    
    public class BalanceCreator {
        
        // MARK: - Private properties
        
        private let balanceCreator: BalanceCreatorProtocol
        private let balancesRepo: BalancesRepo
        
        // MARK: -
        
        init(
            balanceCreator: BalanceCreatorProtocol,
            balancesRepo: BalancesRepo
            ) {
            
            self.balanceCreator = balanceCreator
            self.balancesRepo = balancesRepo
        }
        
        // MARK: - Private
        
        private func tryToCreateBalance(
            asset: String,
            completion: @escaping ((SaleInvestBalanceCreateResult) -> Void)
            ) {
            
            self.balanceCreator.createBalanceForAsset(
                asset,
                completion: { (result) in
                    switch result {
                        
                    case .failed:
                        completion(.failure)
                        
                    case .succeeded:
                        self.fetchCreatedBalance(
                            asset: asset,
                            completion: completion
                        )
                    }
            })
        }
        
        private func fetchCreatedBalance(
            asset: String,
            completion: @escaping ((SaleInvestBalanceCreateResult) -> Void)
            ) {
            
            guard let balance = self.balancesRepo.balancesDetailsValue
                .first(where: { (state) -> Bool in
                    return state.asset == asset
                }),
                case let BalancesRepo.BalanceState.created(details) = balance else {
                    completion(.failure)
                    return
            }
            
            let createdBalance = SaleInvest.Model.BalanceDetails(
                asset: details.asset,
                balance: details.balance,
                balanceId: details.balanceId,
                prevOfferId: nil
            )
            completion(.success(createdBalance))
        }
    }
}

extension SaleInvest.BalanceCreator: SaleInvest.InvestBalanceCreatorProtocol {
    
    func createBalance(
        asset: String,
        completion: @escaping ((SaleInvestBalanceCreateResult) -> Void)
        ) {
        
        self.tryToCreateBalance(asset: asset, completion: completion)
    }
}
