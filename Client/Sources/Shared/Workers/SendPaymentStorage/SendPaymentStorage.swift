import Foundation
import TokenDSDK

class SendPaymentStorage {
    
    // MARK: - Private properties
    
    private var paymentModel: PaymentIntermediateModel
    
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
    
    var payment: PaymentIntermediateModel {
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
        let newPaymentModel = PaymentIntermediateModel(
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
    
    enum SendPaymentStorageError: Swift.Error {
        case cannotBuildModel
    }
    func buildPaymentModel() throws -> PaymentModel {
        
        guard let assetCode = paymentModel.assetCode,
              let destinationAccountId = paymentModel.destinationAccountId,
              let amount = paymentModel.amount,
              let senderFee = paymentModel.senderFee,
              let recipientFee = paymentModel.recipientFee,
              let isPayingFeeForRecipient = paymentModel.isPayingFeeForRecipient
        else {
            throw SendPaymentStorageError.cannotBuildModel
        }
        
        return .init(
            sourceBalanceId: paymentModel.sourceBalanceId,
            assetCode: assetCode,
            destinationAccountId: destinationAccountId,
            recipientEmail: paymentModel.recipientEmail,
            amount: amount,
            senderFee: senderFee,
            recipientFee: recipientFee,
            isPayingFeeForRecipient: isPayingFeeForRecipient,
            description: paymentModel.description,
            reference: paymentModel.reference
        )
    }
}
