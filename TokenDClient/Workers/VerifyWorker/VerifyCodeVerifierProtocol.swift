import Foundation

protocol VerifyCodeVerifierProtocol {

    var canResend: Bool { get }

    func verifyCode(_ code: String, completion: @escaping (Bool) -> Void)
    func resendCode(_ completion: @escaping () -> Void)
}
