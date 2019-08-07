import Foundation
import TokenDWallet

extension TokenDWallet.PublicKey {
    init?(
        base32EncodedString: String,
        expectedVersion: Base32Check.VersionByte
        ) {
        
        guard let data = try? Base32Check.decodeCheck(
            expectedVersion: expectedVersion,
            encoded: base32EncodedString
            ) else {
                return nil
        }
        
        var uint = Uint256()
        uint.wrapped = data
        self = .keyTypeEd25519(uint)
    }
}
