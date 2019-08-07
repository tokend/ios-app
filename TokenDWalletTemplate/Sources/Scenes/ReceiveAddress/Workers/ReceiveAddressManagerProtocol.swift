import Foundation
import RxCocoa
import RxSwift

protocol ReceiveAddressManagerProtocol {
    typealias Address = ReceiveAddress.Address
    
    var address: Address { get }
    func observeAddressChange() -> Observable<Address>
}

extension ReceiveAddress {
    typealias AddressManagerProtocol = ReceiveAddressManagerProtocol
}
