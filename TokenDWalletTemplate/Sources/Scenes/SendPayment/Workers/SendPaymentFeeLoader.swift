import Foundation
import TokenDSDK

enum SendPaymentFeeLoaderResult {
    typealias FeeLoaderError = ApiErrors
    
    case succeeded(SendPayment.Model.FeeModel)
    case failed(FeeLoaderError)
}
protocol SendPaymentFeeLoaderProtocol {
    func loadFee(
        accountId: String,
        asset: String,
        feeType: SendPayment.Model.FeeType,
        amount: Decimal,
        completion: @escaping (_ result: SendPaymentFeeLoaderResult) -> Void
    )
}

extension SendPayment {
    typealias FeeLoaderProtocol = SendPaymentFeeLoaderProtocol
    
    class FeeLoaderWorker: FeeLoaderProtocol {
        
        // MARK: - Private properties
        
        private let feeLoader: TokenDWalletTemplate.FeeLoader
        
        // MARK: -
        
        init(
            feeLoader: TokenDWalletTemplate.FeeLoader
            ) {
            
            self.feeLoader = feeLoader
        }
        
        // MARK: - FeeLoader
        
        func loadFee(
            accountId: String,
            asset: String,
            feeType: Model.FeeType,
            amount: Decimal,
            completion: @escaping (SendPaymentFeeLoaderResult) -> Void
            ) {
            
            self.feeLoader.loadFee(
                accountId: accountId,
                asset: asset,
                feeType: self.feeTypeForFeeType(feeType),
                amount: amount,
                completion: { (result) in
                    switch result {
                        
                    case .failed(let errors):
                        completion(.failed(errors))
                        
                    case .succeeded(let response):
                        let feeModel = Model.FeeModel(
                            asset: response.asset,
                            fixed: response.fixed,
                            percent: response.percent
                        )
                        completion(.succeeded(feeModel))
                    }
            })
        }
        
        private func feeTypeForFeeType(_ type: Model.FeeType) -> FeeResponse.FeeType {
            switch type {
                
            case .payment:
                return .paymentFee
                
            case .offer:
                return .offerFee
                
            case .withdraw:
                return .withdrawalFee
            }
        }
    }
}
