import Foundation

protocol DepositSceneAddressManagerProtocol {
    func renewAddressForAsset(
        asset: String,
        externalSystemType: Int32
    )
    func bindAddressForAsset(
        asset: String,
        externalSystemType: Int32
    )
}

extension DepositScene {
    typealias AddressManagerProtocol = DepositSceneAddressManagerProtocol
}
