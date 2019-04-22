import Foundation
import TokenDSDK
import TokenDWallet

enum SendPaymentAmountFeeLoaderResult {
    typealias FeeLoaderError = ApiErrors
    
    case succeeded(SendPaymentAmount.Model.FeeModel)
    case failed(FeeLoaderError)
}
protocol SendPaymentAmountFeeLoaderProtocol {
    func loadFee(
        accountId: String,
        asset: String,
        feeType: SendPaymentAmount.Model.FeeType,
        amount: Decimal,
        subtype: Int32,
        completion: @escaping (_ result: SendPaymentAmountFeeLoaderResult) -> Void
    )
}

extension SendPaymentAmount {
    typealias FeeLoaderProtocol = SendPaymentAmountFeeLoaderProtocol
    
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
            subtype: Int32,
            completion: @escaping (SendPaymentAmountFeeLoaderResult) -> Void
            ) {
            
            self.feeLoader.loadFee(
                accountId: accountId,
                asset: asset,
                feeType: self.feeTypeForFeeType(feeType),
                amount: amount,
                subtype: subtype,
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
