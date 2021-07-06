import Foundation
import DLCryptoKit

enum WalletDataProviderResult {

    case success(WalletDataSerializable, [ECDSA.KeyData])
    case failure(Swift.Error)
}

protocol WalletDataProviderProtocol {

    func walletData(
        for login: String,
        password: String,
        completion: @escaping (WalletDataProviderResult) -> Void
    )
}
