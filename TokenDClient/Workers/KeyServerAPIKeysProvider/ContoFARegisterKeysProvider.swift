//import Foundation
//import TokenDSDK
//import TokenDWallet
//import DLCryptoKit
//
//class ContoFARegisterKeysProvider {
//
//    enum RequestDefaultSignerRoleError: Swift.Error {
//        case cannotCastRole
//    }
//    enum RequestPaymentsSignerRoleId: Swift.Error {
//        case cannotCastRole
//    }
//
//    private let mainKeyPair: ECDSA.KeyData
//    private let paymentsKeyPair: ECDSA.KeyData
//
//    private let keyValuesApi: KeyValuesApiV3
//    private let cardsApi: CardsApi
//
//    init(
//        keyValuesApi: KeyValuesApiV3,
//        cardsApi: CardsApi
//    ) throws {
//
//        mainKeyPair = try .init()
//        paymentsKeyPair = try .init()
//
//        self.keyValuesApi = keyValuesApi
//        self.cardsApi = cardsApi
//    }
//}
//
//// MARK: - Private methods
//
//private extension ContoFARegisterKeysProvider {
//
//    func getRoles(
//        completion: @escaping (Result<[Signer], Swift.Error>) -> Void
//    ) {
//
//        keyValuesApi
//            .requestKeyValue(
//                key: "signer_role:default",
//                completion: { (result) in
//
//                    switch result {
//
//                    case .failure(let error):
//                        completion(.failure(error))
//
//                    case .success(let document):
//
//                        guard let role = document.data?.value?.u32
//                        else {
//                            completion(.failure(RequestDefaultSignerRoleError.cannotCastRole))
//                            return
//                        }
//
//                        self.requestPaymentsSignerRoleId(
//                            defaultSignerRole: UInt64(role),
//                            completion: completion
//                        )
//                    }
//                })
//    }
//
//    func requestPaymentsSignerRoleId(
//        defaultSignerRole: UInt64,
//        completion: @escaping (Result<[Signer], Swift.Error>) -> Void
//    ) {
//
//        cardsApi
//            .requestInfo(
//                completion: { [weak self] (result) in
//
//                    switch result {
//
//                    case .failure(let error):
//                        completion(.failure(error))
//
//                    case .success(let document):
//                        guard let id = document.data?.signer?.id,
//                              let role = document.data?.role?.id,
//                              let roleId = UInt64(role)
//                        else {
//                            completion(.failure(RequestPaymentsSignerRoleId.cannotCastRole))
//                            return
//                        }
//
//                        self?.createSigners(
//                            defaultSignerRole: defaultSignerRole,
//                            paymentsSignerId: id,
//                            paymentsSignerRole: roleId,
//                            completion: completion
//                        )
//                    }
//                })
//    }
//
//    func createSigners(
//        defaultSignerRole: UInt64,
//        paymentsSignerId: String,
//        paymentsSignerRole: UInt64,
//        completion: @escaping (Result<[Signer], Swift.Error>) -> Void
//    ) {
//
//        let mainAccountId = Base32Check.encode(
//            version: .accountIdEd25519,
//            data: mainKeyPair.getPublicKeyData()
//        )
//        let mainSigner: Signer = .init(
//            id: mainAccountId,
//            type: Signer.defaultType,
//            attributes: .init(
//                roleId: defaultSignerRole,
//                weight: Signer.defaultWeight,
//                identity: Signer.defaultIdentity,
//                details: Signer.defaultDetails
//            )
//        )
//
//        let paymentsAccountId = Base32Check.encode(
//            version: .accountIdEd25519,
//            data: paymentsKeyPair.getPublicKeyData()
//        )
//        let paymentsSigner: Signer = .init(
//            id: paymentsAccountId,
//            type: Signer.defaultType,
//            attributes: .init(
//                roleId: paymentsSignerRole,
//                weight: 500,
//                identity: 0,
//                details: Signer.defaultDetails
//            )
//        )
//
//        let paymentServiceSigner: Signer = .init(
//            id: paymentsSignerId,
//            type: Signer.defaultType,
//            attributes: .init(
//                roleId: paymentsSignerRole,
//                weight: 500,
//                identity: 10,
//                details: Signer.defaultDetails
//            )
//        )
//
//        completion(.success([mainSigner, paymentsSigner, paymentServiceSigner]))
//    }
//}
//
//extension ContoFARegisterKeysProvider: KeyServerAPIKeysProviderProtocol {
//
//    var requestSigningKey: ECDSA.KeyData {
//        mainKeyPair
//    }
//
//    var mainKey: ECDSA.KeyData {
//        mainKeyPair
//    }
//
//    var keys: [ECDSA.KeyData] {
//        [mainKeyPair, paymentsKeyPair]
//    }
//
//    func getSigners(
//        completion: @escaping (Result<[Signer], Swift.Error>) -> Void
//    ) {
//
//        getRoles(
//            completion: completion
//        )
//    }
//}
