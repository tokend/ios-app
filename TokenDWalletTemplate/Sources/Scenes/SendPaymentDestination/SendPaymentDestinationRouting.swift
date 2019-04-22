import Foundation

extension SendPaymentDestination {
    public struct Routing {
        let onSelectContactEmail: (_ completion: @escaping SelectContactEmailCompletion) -> Void
        let onPresentQRCodeReader: (_ completion: @escaping QRCodeReaderCompletion) -> Void
    }
}
