import RxCocoa
import RxSwift
import UIKit

extension ReceiveAddress {
    class ReceiveAddressManager {
    
        private let addressBehaviorRelay: BehaviorRelay<ReceiveAddressManagerProtocol.Address>
        
        init(accountId: String) {
            self.addressBehaviorRelay = BehaviorRelay(value: accountId)
        }
    }
}

extension ReceiveAddress.ReceiveAddressManager: ReceiveAddress.AddressManagerProtocol {
    var address: ReceiveAddressManagerProtocol.Address {
        return self.addressBehaviorRelay.value
    }
    
    func observeAddressChange() -> Observable<ReceiveAddressManagerProtocol.Address> {
        return self.addressBehaviorRelay.asObservable()
    }
}
