import Foundation
import TokenDSDK
import TokenDWallet
import DLCryptoKit

class BaseLoginChanger {

    // MARK: - Private properties

    private let flowControllerStack: FlowControllerStack
    private let walletDataProvider: WalletDataProviderProtocol

    // MARK: -

    init(
        flowControllerStack: FlowControllerStack,
        walletDataProvider: WalletDataProviderProtocol
    ) {

        self.flowControllerStack = flowControllerStack
        self.walletDataProvider = walletDataProvider
    }
}

// MARK: - Private methods

private extension BaseLoginChanger {

    func fetchWalletData(
        oldLogin: String,
        newLogin: String,
        password: String,
        completion: @escaping (Result<Void, Swift.Error>) -> Void
    ) {

        walletDataProvider.walletData(
            for: oldLogin,
            password: password,
            completion: { [weak self] (result) in

                switch result {

                case .failure(let error):
                    completion(.failure(error))

                case .success(let walletData, let keyPairs):
                    self?.requestAccountSigners(
                        oldLogin: oldLogin,
                        newLogin: newLogin,
                        password: password,
                        walletData: walletData,
                        keyPairs: keyPairs,
                        completion: completion
                    )
                }
            })
    }

    enum RequestAccountSignersError: Swift.Error {

        case emptySignersDocument
    }
    func requestAccountSigners(
        oldLogin: String,
        newLogin: String,
        password: String,
        walletData: WalletDataSerializable,
        keyPairs: [ECDSA.KeyData],
        completion: @escaping (Result<Void, Swift.Error>) -> Void
    ) {

        flowControllerStack.apiV3.accountsApi.requestSigners(
            accountId: walletData.accountId,
            completion: { [weak self] (result) in

                switch result {

                case .failure(let error):
                    completion(.failure(error))

                case .success(let document):
                    guard let fetchedSigners = document.data else {
                        completion(.failure(RequestAccountSignersError.emptySignersDocument))
                        return
                    }

                    self?.createWallet(
                        oldLogin: oldLogin,
                        newLogin: newLogin,
                        password: password,
                        walletData: walletData,
                        keyPairs: keyPairs,
                        signers: fetchedSigners,
                        completion: completion
                    )
                }
        })
    }

    func createWallet(
        oldLogin: String,
        newLogin: String,
        password: String,
        walletData: WalletDataSerializable,
        keyPairs: [ECDSA.KeyData],
        signers: [Horizon.SignerResource],
        completion: @escaping (Result<Void, Swift.Error>) -> Void
    ) {

        let infoSigners = signers.compactMap { (signer) -> WalletInfoModelV2.WalletInfoData.Relationships.Signer? in

            guard let id = signer.id,
                  let role = signer.role,
                  let roleStringId = role.id,
                  let roleId = Uint64(roleStringId)
            else {
                return nil
            }

            var details = WalletInfoModelV2.WalletInfoData.Relationships.Signer.defaultDetails
            if let detailsData = try? JSONSerialization.data(
                withJSONObject: signer.details,
                options: []
                ),
                let encodedDetails = String(data: detailsData, encoding: .utf8) {

                details = encodedDetails
            }

            return .init(
                id: id,
                type: signer.type,
                attributes: .init(
                    roleId: roleId,
                    weight: UInt64(signer.weight),
                    identity: UInt64(signer.identity),
                    details: details
                )
            )
        }
        let walletInfo = WalletInfoBuilderV2.createWalletInfo(
            login: newLogin,
            password: password,
            kdfParams: walletData.walletKDF.kdfParams.getKDFParams(),
            salt: Common.Random.generateRandom(length: walletData.walletKDF.salt.count),
            keys: keyPairs,
            signers: infoSigners,
            transaction: nil
        )

        switch walletInfo {

        case .failure(let error):
            completion(.failure(error))

        case .success(let walletInfo):
            createWallet(
                oldWalletId: walletData.walletId,
                walletInfo: walletInfo,
                completion: completion
            )
        }
    }

    func createWallet(
        oldWalletId: String,
        walletInfo: WalletInfoModelV2,
        completion: @escaping (Result<Void, Swift.Error>) -> Void
    ) {

        flowControllerStack
            .keyServerApi
            .postWallet(
                walletId: oldWalletId,
                walletInfo: walletInfo,
                completion: { (result) in

                    switch result {

                    case .failure(let error):
                        completion(.failure(error))

                    case .success:
                        completion(.success(()))
                    }
                }
            )
    }
}

// MARK: - LoginChangerProtocol

extension BaseLoginChanger: LoginChangerProtocol {

    func changeLogin(
        oldLogin: String,
        newLogin: String,
        password: String,
        completion: @escaping (Result<Void, Swift.Error>) -> Void
    ) {

        fetchWalletData(
            oldLogin: oldLogin,
            newLogin: newLogin,
            password: password,
            completion: completion
        )
    }
}
