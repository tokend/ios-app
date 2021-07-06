import Foundation
import TokenDSDK

class VerifyCodeWalletVerifier {

    private let keyServerApi: KeyServerApi
    private let walletId: String

    init(
        keyServerApi: KeyServerApi,
        walletId: String
    ) {

        self.keyServerApi = keyServerApi
        self.walletId = walletId
    }
}

extension VerifyCodeWalletVerifier: VerifyCodeVerifierProtocol {

    var canResend: Bool {
        return true
    }

    func resendCode(_ completion: @escaping () -> Void) {
        keyServerApi.resendVerificationCode(
            walletId: walletId,
            completion: { (result) in

                switch result {

                case .failure:
                    break

                case .success:
                    break
                }

                completion()
        })
    }

    func verifyCode(
        _ code: String,
        completion: @escaping (Bool) -> Void
    ) {

        keyServerApi.verifyWallet(
            walletId: walletId,
            token: code,
            completion: { (result) in

                switch result {

                case .failure:
                    completion(false)

                case .success:
                    completion(true)
                }
        })
    }
}

