import Foundation
import TokenDSDK

class SendPaymentStorage {
    
    // MARK: - Private properties
    
    private var paymentModel: PaymentModel
    
    // MARK: -
    
    init(
        balanceId: String
    ) {
        paymentModel = .init(
            sourceBalanceId: balanceId,
            reference: Date().description
        )
    }
}

// MARK: - SendPaymentStorageProtocol

extension SendPaymentStorage: SendPaymentStorageProtocol {
    var payment: PaymentModel {
        return paymentModel
    }
    
    func updatePaymentModel(
        sourceBalanceId: String? = nil,
        assetCode: String? = nil,
        destinationAccountId: String? = nil,
        recipientEmail: String? = nil,
        amount: Decimal? = nil,
        senderFee: Horizon.CalculatedFeeResource? = nil,
        recipientFee: Horizon.CalculatedFeeResource? = nil,
        isPayingFeeForRecipient: Bool? = nil,
        description: String? = nil
    ) {
        let newPaymentModel = PaymentModel(
            sourceBalanceId: sourceBalanceId ?? paymentModel.sourceBalanceId,
            assetCode: assetCode ?? paymentModel.assetCode,
            destinationAccountId: destinationAccountId ?? paymentModel.destinationAccountId,
            recipientEmail: recipientEmail ?? paymentModel.recipientEmail,
            amount: amount ?? payment.amount,
            senderFee: senderFee ?? payment.senderFee,
            recipientFee: recipientFee ?? payment.recipientFee,
            isPayingFeeForRecipient: isPayingFeeForRecipient ?? payment.isPayingFeeForRecipient,
            description: description,
            reference: payment.reference
        )
        
        paymentModel = newPaymentModel
    }
}
