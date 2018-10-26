import Foundation
import TokenDWallet
import TokenDSDK

extension DepositScene {
    class AddressManager: AddressManagerProtocol {
        
        private let balanceBinder: BalanceBinderProtocol
        
        // MARK: -
        
        init(
            balanceBinder: BalanceBinderProtocol
            ) {
            
            self.balanceBinder = balanceBinder
        }
        
        // MARK: - Public
        
        func renewAddressForAsset(asset: String, externalSystemType: Int32) {
            self.bindAddress(asset, externalSystemType: externalSystemType)
        }
        
        func bindAddressForAsset(asset: String, externalSystemType: Int32) {
            self.bindAddress(asset, externalSystemType: externalSystemType)
        }
        
        // MARK: - Private
        
        private func bindAddress(
            _ asset: String,
            externalSystemType: Int32
            ) {
            
            self.balanceBinder.bindBalance(
                asset,
                toAccount: externalSystemType,
                completion: { (_) in }
            )
        }
    }
}
