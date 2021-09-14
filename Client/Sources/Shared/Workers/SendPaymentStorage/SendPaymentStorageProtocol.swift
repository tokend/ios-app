import Foundation
import TokenDSDK

public protocol SendPaymentStorageProtocol {
    
    var payment: PaymentModel { get }
    
    func updatePaymentModel(
        sourceBalanceId: String?,
        assetCode: String?,
        destinationAccountId: String?,
        recipientEmail: String?,
        amount: Decimal?,
        senderFee: Horizon.CalculatedFeeResource?,
        recipientFee: Horizon.CalculatedFeeResource?,
        isPayingFeeForRecipient: Bool?,
        description: String?
    )
}

public struct PaymentModel {
    
    var sourceBalanceId: String
    var assetCode: String?
    var destinationAccountId: String?
    var recipientEmail: String?
    var amount: Decimal?
    var senderFee: Horizon.CalculatedFeeResource?
    var recipientFee: Horizon.CalculatedFeeResource?
    var isPayingFeeForRecipient: Bool?
    var description: String?
    var reference: String
}
