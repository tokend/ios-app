import Foundation
import TokenDSDK

public protocol SendPaymentStorageProtocol {
    
    typealias PaymentIntermediateModel = SendPaymentStorageProtocolPaymentIntermediateModel
    typealias PaymentModel = SendPaymentStorageProtocolPaymentModel
    
    var payment: PaymentIntermediateModel { get }
    
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
    
    func buildPaymentModel() throws -> PaymentModel
}

public struct SendPaymentStorageProtocolPaymentIntermediateModel {
    
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

public struct SendPaymentStorageProtocolPaymentModel {
    let sourceBalanceId: String
    let assetCode: String
    let destinationAccountId: String
    let recipientEmail: String?
    let amount: Decimal
    let senderFee: Horizon.CalculatedFeeResource
    let recipientFee: Horizon.CalculatedFeeResource
    let isPayingFeeForRecipient: Bool
    let description: String?
    let reference: String
}
