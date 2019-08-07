import UIKit

protocol ReceiveAddressSceneQRCodeGeneratorProtocol {
    func generateQRCodeFromString(
        _ string: String,
        withTintColor tintColor: UIColor,
        backgroundColor: UIColor,
        size: CGSize,
        completion: @escaping (UIImage?) -> Void
    )
}

extension ReceiveAddress {
    typealias ReceiveAddressQRCodeGeneratorProtocol = ReceiveAddressSceneQRCodeGeneratorProtocol
}

extension QRCodeGenerator: ReceiveAddress.ReceiveAddressQRCodeGeneratorProtocol { }
