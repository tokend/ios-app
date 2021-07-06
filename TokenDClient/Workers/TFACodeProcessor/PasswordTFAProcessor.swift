import Foundation
import TokenDSDK
import DLCryptoKit

class PasswordTFAProcessor {
    
    // MARK: - Private properties
    
    private let tokenSignData: ApiCallbacks.TokenSignData
    private let tfaDataProvider: TFADataProviderProtocol
    
    // MARK: -
    
    init(
        tokenSignData: ApiCallbacks.TokenSignData,
        tfaDataProvider: TFADataProviderProtocol
    ) {
        
        self.tokenSignData = tokenSignData
        self.tfaDataProvider = tfaDataProvider
    }
}

// MARK: - Private methods

private extension PasswordTFAProcessor {
    
    enum ProcessInputError: Swift.Error {
        
        case noData
    }
    func processInput(
        password: String
    ) throws -> String {
        
        guard let login = tfaDataProvider.getUserLogin(),
              let kdfParams = tfaDataProvider.getKdfParams()
        else {
            throw ProcessInputError.noData
        }
        
        return try getSignedTokenForPassword(
            password,
            keychainData: tokenSignData.keychainData,
            login: login,
            token: tokenSignData.token,
            walletKDF: WalletKDFParams(
                kdfParams: kdfParams,
                salt: tokenSignData.salt
            )
        )
    }
    
    enum SignedTokenForPasswordError: Swift.Error {
        
        case noKeyPair
        case cannotGetTokenData
    }
    func getSignedTokenForPassword(
        _ password: String,
        keychainData: Data,
        login: String,
        token: String,
        walletKDF: WalletKDFParams
    ) throws -> String {
        
        guard let keyPair = try KeyPairBuilder.getKeyPairs(
            forLogin: login,
            password: password,
            keychainData: keychainData,
            walletKDF: walletKDF
        ).first
        else {
            throw SignedTokenForPasswordError.noKeyPair
        }
        
        guard let data = token.data(using: .utf8)
        else {
            throw SignedTokenForPasswordError.cannotGetTokenData
        }
        
        return try ECDSA.signED25519(
            data: data,
            keyData: keyPair
        ).base64EncodedString()
    }
}

// MARK: - TFACodeProcessorProtocol

extension PasswordTFAProcessor: TFACodeProcessorProtocol {
    
    func process(
        tfaCode: String
    ) throws -> String {
        
        try processInput(
            password: tfaCode
        )
    }
}
