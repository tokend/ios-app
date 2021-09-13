import Foundation
import RxSwift
import RxCocoa

public protocol SendConfirmationScenePaymentProviderProtocol {
    
    var payment: SendConfirmationScene.Model.Payment? { get }
    
    func observePayment() -> Observable<SendConfirmationScene.Model.Payment?>
}

extension SendConfirmationScene {
    public typealias PaymentProviderProtocol = SendConfirmationScenePaymentProviderProtocol
}
