import Foundation
import TokenDSDK

public protocol PaymentSenderProtocol {
    
    func sendPayment(
        sourceBalanceId: String,
        destinationAccountId: String,
        amount: Decimal,
        senderFee: Horizon.CalculatedFeeResource,
        recipientFee: Horizon.CalculatedFeeResource,
        isPayingFeeForRecipient: Bool,
        description: String,
        reference: String,
        completion: @escaping (Swift.Result<Void, Swift.Error>) -> Void
    )
}

public enum SendPaymentWorkerError: Swift.Error {
    case noSenderAccountId
    case noBalanceId
    case noDestinationAccountId
}
