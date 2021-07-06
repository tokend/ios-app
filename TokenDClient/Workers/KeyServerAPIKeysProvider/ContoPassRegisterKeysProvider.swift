import Foundation
import TokenDSDK
import TokenDWallet
import DLCryptoKit

class ContoPassRegisterKeysProvider {
    
    enum RequestDefaultSignerRoleError: Swift.Error {
        case cannotCastRole
    }
    
    private let mainKeyPair: ECDSA.KeyData
    
    private let keyValuesApi: KeyValuesApiV3
    
    init(
        keyValuesApi: KeyValuesApiV3
    ) throws {
        
        mainKeyPair = try .init()
        
        self.keyValuesApi = keyValuesApi
    }
}

// MARK: - Private methods

private extension ContoPassRegisterKeysProvider {
    
    func getRoles(
        completion: @escaping (Result<[Signer], Swift.Error>) -> Void
    ) {

        keyValuesApi
            .requestKeyValue(
                key: "signer_role:default",
                completion: { [weak self] (result) in

                    switch result {

                    case .failure(let error):
                        completion(.failure(error))

                    case .success(let document):
                        guard let role = document.data?.value?.u32
                        else {
                            completion(.failure(RequestDefaultSignerRoleError.cannotCastRole))
                            return
                        }
                        
                        self?.createSigners(
                            defaultSignerRole: UInt64(role),
                            completion: completion
                        )
                    }
                })
    }
    
    func createSigners(
        defaultSignerRole: UInt64,
        completion: @escaping (Result<[Signer], Swift.Error>) -> Void
    ) {
        
        let keyPair = mainKey
        let accountId = Base32Check.encode(
            version: .accountIdEd25519,
            data: keyPair.getPublicKeyData()
        )
        let signer: Signer = .init(
            id: accountId,
            type: Signer.defaultType,
            attributes: .init(
                roleId: defaultSignerRole,
                weight: Signer.defaultWeight,
                identity: Signer.defaultIdentity,
                details: Signer.defaultDetails
            )
        )
        
        completion(.success([signer]))
    }
}

extension ContoPassRegisterKeysProvider: KeyServerAPIKeysProviderProtocol {
    
    var requestSigningKey: ECDSA.KeyData {
        mainKeyPair
    }
    
    var mainKey: ECDSA.KeyData {
        mainKeyPair
    }
    
    var keys: [ECDSA.KeyData] {
        [mainKeyPair]
    }
    
    func getSigners(
        completion: @escaping (Result<[Signer], Swift.Error>) -> Void
    ) {
        
        getRoles(
            completion: completion
        )
    }
}
