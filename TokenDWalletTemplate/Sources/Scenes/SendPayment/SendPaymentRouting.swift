import Foundation

extension SendPayment {
    struct Routing {
        let onShowProgress: () -> Void
        let onHideProgress: () -> Void
        let onShowError: (_ erroMessage: String) -> Void
        let onPresentQRCodeReader: (_ completion: @escaping QRCodeReaderCompletion) -> Void
        let onPresentPicker: (
        _ title: String,
        _ options: [String],
        _ onSelect: @escaping (_ index: Int) -> Void
        ) -> Void
        let onSendAction: ((_ sendModel: Model.SendPaymentModel) -> Void)?
        let onSendWithdraw: ((_ sendModel: Model.SendWithdrawModel) -> Void)?
    }
}
