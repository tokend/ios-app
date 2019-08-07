import Foundation

protocol ReceiveAddressShareUtilProtocol {
    var canBeCopied: Bool { get }
    var canBeShared: Bool { get }
    
    func stringToCopyAddress(
        _ address: ReceiveAddress.Address
        ) -> String
    
    func itemsToShareAddress(
        _ address: ReceiveAddress.Address
        ) -> [Any]
}

extension ReceiveAddress {
    typealias ShareUtilProtocol = ReceiveAddressShareUtilProtocol
}
