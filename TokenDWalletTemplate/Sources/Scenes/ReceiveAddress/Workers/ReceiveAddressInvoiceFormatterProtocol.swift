import Foundation

protocol ReceiveAddressInvoiceFormatterProtocol {
    func qrValueForAddress(
        _ address: ReceiveAddress.Address
        ) -> String

    func valueForAddress(
        _ address: ReceiveAddress.Address
        ) -> String
    
    var estimatedNumberOfLinesInValue: Int { get }
}

extension ReceiveAddress {
    typealias InvoiceFormatterProtocol = ReceiveAddressInvoiceFormatterProtocol
}
