import Foundation

class BalanceCreator: BalanceCreatorProtocol {
    
    private let balancesRepo: BalancesRepo
    
    init(
        balancesRepo: BalancesRepo
        ) {
        
        self.balancesRepo = balancesRepo
    }
    
    func createBalanceForAsset(
        _ asset: BalanceCreatorProtocol.Asset,
        completion: @escaping (BalanceCreatorProtocol.CreateBalanceResult) -> Void
        ) {
        
        self.balancesRepo.createBalanceForAsset(
            asset
        ) { (result) in
            switch result {
                
            case .succeeded:
                completion(.succeeded)
                
            case .failed:
                completion(.failed)
            }
        }
    }
}
