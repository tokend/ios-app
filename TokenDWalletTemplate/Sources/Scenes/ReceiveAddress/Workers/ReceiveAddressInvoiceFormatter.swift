import UIKit

extension ReceiveAddress {
    struct InvoiceFormatter: InvoiceFormatterProtocol {
        
        var estimatedNumberOfLinesInValue: Int {
            return 1
        }
        
        func qrValueForAddress(
            _ address: ReceiveAddress.Address
            ) -> String {
            
            return address
        }
        
        func valueForAddress(
            _ address: ReceiveAddress.Address
            ) -> String {
            
            return address
        }
    }
}
