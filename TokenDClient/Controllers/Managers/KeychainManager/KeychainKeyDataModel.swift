import Foundation
import TokenDSDK
import TokenDWallet
import DLCryptoKit

class KeychainKeyDataModel: Codable {

    typealias Version = UInt
    typealias KeyData = ECDSA.KeyData

    let version: Version
    let encodedKeyData: Data // encoded keys

    // MARK: -

    init(version: Version, encodedKeyData: Data) {
        self.version = version
        self.encodedKeyData = encodedKeyData
    }

    // MARK: - Public

    func getKeyData() -> [KeyData]? {
        return KeychainKeyDataModel.decodeKeyData(self.encodedKeyData, version: self.version)
    }

    // MARK: - Coding

    static func decodeKeyData(_ encodedKeyData: Data, version: Version) -> [KeyData]? {
        switch version {

        case 1:
            guard let keyDataModel = try? JSONDecoder().decode(
                KeychainCodableKeyDataV1.self,
                from: encodedKeyData
            ) else {
                return nil
            }

            guard let keyData = try? keyDataModel.seeds.map({ try ECDSA.KeyData(seed: try Base32Check.decodeCheck(expectedVersion: .seedEd25519, encoded: $0)) })
            else {
                return nil
            }
            return keyData

        default:
            let function = #function
            print(
                Localized(
                    .unsupported_version,
                    replace: [
                        .unsupported_version_replace_function: function
                    ]
                )
            )
            return nil
        }
    }

    static func encodeKeyData(_ keyData: [KeyData]) -> (version: Version, encodedKeyData: Data)? {
        let seeds = keyData.map { Base32Check.encode(version: .seedEd25519, data: $0.getSeedData()) }
        let keyDataModel = KeychainCodableKeyDataV1(seeds: seeds)
        guard let encodedKeyData = try? JSONEncoder().encode(keyDataModel) else {
            return nil
        }
        return (1, encodedKeyData)
    }
}
