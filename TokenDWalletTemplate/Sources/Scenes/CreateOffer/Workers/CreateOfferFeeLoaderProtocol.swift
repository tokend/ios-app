import Foundation
import TokenDSDK

enum CreateOfferFeeLoaderResult {
    typealias FeeLoaderError = ApiErrors
    
    case succeeded(CreateOffer.Model.FeeModel)
    case failed(FeeLoaderError)
}
protocol CreateOfferFeeLoaderProtocol {
    typealias LoadFeeResult = CreateOfferFeeLoaderResult
    
    func loadFee(
        accountId: String,
        asset: String,
        amount: Decimal,
        completion: @escaping (_ result: LoadFeeResult) -> Void
    )
}

extension CreateOffer {
    typealias FeeLoaderProtocol = CreateOfferFeeLoaderProtocol
}
