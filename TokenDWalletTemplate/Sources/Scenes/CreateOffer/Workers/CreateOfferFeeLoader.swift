import Foundation
import TokenDSDK

extension CreateOffer {
    class FeeLoader {
        
        // MARK: - Private properties
        
        private let feeLoader: TokenDWalletTemplate.FeeLoader
        
        // MARK: -
        
        init(
            feeLoader: TokenDWalletTemplate.FeeLoader
            ) {
            
            self.feeLoader = feeLoader
        }
    }
}

extension CreateOffer.FeeLoader: CreateOffer.FeeLoaderProtocol {
    func loadFee(
        accountId: String,
        asset: String,
        amount: Decimal,
        completion: @escaping (CreateOfferFeeLoaderProtocol.LoadFeeResult) -> Void
        ) {
        
        self.feeLoader.loadFee(
            accountId: accountId,
            asset: asset,
            feeType: .offerFee,
            amount: amount,
            completion: { (result) in
                switch result {
                    
                case .failed(let errors):
                    completion(.failed(errors))
                    
                case .succeeded(let response):
                    let feeModel = CreateOffer.Model.FeeModel(
                        asset: response.asset,
                        fixed: response.fixed,
                        percent: response.percent
                    )
                    completion(.succeeded(feeModel))
                }
        })
    }
}
