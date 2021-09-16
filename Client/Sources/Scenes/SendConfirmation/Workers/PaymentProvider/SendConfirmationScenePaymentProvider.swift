import Foundation
import RxSwift
import RxCocoa

extension SendConfirmationScene {
    class PaymentProvider {
        
        // MARK: - Private properties
        
        private let paymentBehaviorRelay: BehaviorRelay<SendConfirmationScene.Model.Payment?>
        
        // MARK: -
        
        init(
            paymentModel: SendPaymentStorageProtocolPaymentModel
        ) {
            
            let fee: Decimal
            if paymentModel.isPayingFeeForRecipient {
                fee = paymentModel.senderFee.calculatedPercent
                    + paymentModel.senderFee.fixed
                    + paymentModel.recipientFee.calculatedPercent
                    + paymentModel.recipientFee.fixed
            } else {
                fee = paymentModel.senderFee.calculatedPercent + paymentModel.senderFee.fixed
            }
            
            paymentBehaviorRelay = .init(
                value: .init(
                    recipientAccountId: paymentModel.destinationAccountId,
                    recipientEmail: paymentModel.recipientEmail,
                    amount: paymentModel.amount,
                    assetCode: paymentModel.assetCode,
                    fee: fee,
                    description: paymentModel.description,
                    toRecieve: 0
                )
            )
        }
    }
}

// MARK: - SendConfirmationScenePaymentProviderProtocol

extension SendConfirmationScene.PaymentProvider: SendConfirmationScene.PaymentProviderProtocol {
    var payment: SendConfirmationScene.Model.Payment? {
        paymentBehaviorRelay.value
    }
    
    func observePayment() -> Observable<SendConfirmationScene.Model.Payment?> {
        return paymentBehaviorRelay.asObservable()
    }
}
