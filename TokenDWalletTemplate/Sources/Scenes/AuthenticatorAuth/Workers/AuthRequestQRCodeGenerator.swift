import UIKit

protocol AuthRequestSceneQRCodeGeneratorProtocol {
    func generateQRCodeFromString(
        _ string: String,
        withTintColor tintColor: UIColor,
        backgroundColor: UIColor,
        size: CGSize,
        completion: @escaping (UIImage?) -> Void
    )
}

extension AuthenticatorAuth {
    typealias AuthRequestQRCodeGeneratorProtocol = AuthRequestSceneQRCodeGeneratorProtocol
}

extension QRCodeGenerator: AuthenticatorAuth.AuthRequestQRCodeGeneratorProtocol { }
