import Foundation
import TokenDSDK

class FeeLoader {
    
    // MARK: - Private properties
    
    private let generalApi: GeneralApi
    
    // MARK: -
    
    init(generalApi: GeneralApi) {
        self.generalApi = generalApi
    }
    
    // MARK: - FeeLoader
    
    enum LoadFeeResult {
        case succeeded(FeeResponse)
        case failed(ApiErrors)
    }
    func loadFee(
        accountId: String,
        asset: String,
        feeType: FeeResponse.FeeType,
        amount: Decimal,
        subtype: Int32 = 0,
        completion: @escaping (LoadFeeResult) -> Void
        ) {
        
        self.generalApi.requestFee(
            accountId: accountId,
            asset: asset,
            feeType: feeType,
            amount: amount,
            subtype: subtype,
            completion: { (result) in
                switch result {
                    
                case .failed(let errors):
                    completion(.failed(errors))
                    
                case .succeeded(let response):
                    completion(.succeeded(response))
                }
        })
    }
}
