import Foundation
import TokenDSDK
import DLCryptoKit

protocol KeyServerAPIKeysProviderProtocol {
    
    typealias Signer = WalletInfoModelV2.WalletInfoData.Relationships.Signer
    
    var requestSigningKey: ECDSA.KeyData { get }
    var mainKey: ECDSA.KeyData { get }
    var keys: [ECDSA.KeyData] { get }
    
    func getSigners(
        completion: @escaping (Result<[Signer], Swift.Error>) -> Void
    )
}
