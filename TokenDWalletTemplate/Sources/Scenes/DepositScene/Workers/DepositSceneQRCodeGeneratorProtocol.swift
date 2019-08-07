import UIKit

protocol DepositSceneQRCodeGeneratorProtocol {
    func generateQRCodeFromString(
        _ string: String,
        withTintColor tintColor: UIColor,
        backgroundColor: UIColor,
        size: CGSize,
        completion: @escaping (UIImage?) -> Void
    )
}

extension DepositScene {
    typealias QRCodeGeneratorProtocol = DepositSceneQRCodeGeneratorProtocol
}

extension QRCodeGenerator: DepositScene.QRCodeGeneratorProtocol { }
