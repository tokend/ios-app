import Foundation
import RxSwift
import RxCocoa

extension SendConfirmationScene {
    class PaymentProvider {
        
        // MARK: - Private properties
        
        private let paymentBehaviorRelay: BehaviorRelay<SendConfirmationScene.Model.Payment?>
        
        // MARK: -
        
        init(
            recipientAccountId: String,
            recipientEmail: String?,
            amount: Decimal,
            assetCode: String,
            fee: Decimal,
            description: String?
        ) {
            
            paymentBehaviorRelay = .init(
                value: .init(
                    recipientAccountId: recipientAccountId,
                    recipientEmail: recipientEmail,
                    amount: amount,
                    assetCode: assetCode,
                    fee: fee,
                    description: description,
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
