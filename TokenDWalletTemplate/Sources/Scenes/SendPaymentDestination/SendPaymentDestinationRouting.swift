import Foundation

extension SendPaymentDestination {
    public struct Routing {
        let onSelectContactEmail: (_ completion: @escaping SelectContactEmailCompletion) -> Void
        let onPresentQRCodeReader: (_ completion: @escaping QRCodeReaderCompletion) -> Void
        let showWithdrawConformation: (_ sendWithdrawModel: Model.SendWithdrawModel) -> Void
        let showSendAmount: (_ destination: Model.SendDestinationModel) -> Void
        let showProgress: () -> Void
        let hideProgress: () -> Void
        let showError: (_ message: String) -> Void
    }
}
