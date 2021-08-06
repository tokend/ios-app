import Foundation
import TokenDSDK
import TokenDWallet
import DLCryptoKit

class WalletDataProvider {

    typealias VerifyWalletCompletion = () -> Void
    typealias OnVerifyWallet = (_ walletId: String, _ completion: @escaping VerifyWalletCompletion) -> Void

    // MARK: - Private properties

    private let flowControllerStack: FlowControllerStack
    private let onVerifyWallet: OnVerifyWallet
    private let loginService: KeyServerLoginService

    // MARK: -

    init(
        flowControllerStack: FlowControllerStack,
        onVerifyWallet: @escaping OnVerifyWallet
    ) {

        self.flowControllerStack = flowControllerStack
        self.onVerifyWallet = onVerifyWallet
        self.loginService = .init(
            walletKDFProvider: flowControllerStack.keyServerApi,
            walletDataProvider: flowControllerStack.keyServerApi
        )
    }
}

// MARK: - Private methods

private extension WalletDataProvider {

    func fetchNetworkInfo(
        login: String,
        password: String,
        completion: @escaping (WalletDataProviderResult) -> Void
    ) {

        flowControllerStack
            .apiV3
            .infoApi
            .requestInfo(completion: { [weak self] (result) in

                switch result {

                case .failure(let error):
                    completion(.failure(error))

                case .success(let network):
                    self?.signIn(
                        login: login,
                        password: password,
                        network: network,
                        completion: completion
                    )
                }
            })
    }

    enum SignInError: Swift.Error {

        case failedToBuildWalletData
    }
    func signIn(
        login: String,
        password: String,
        network: NetworkInfoModel,
        completion: @escaping (WalletDataProviderResult) -> Void
    ) {
        
        loginService.loginWith(
            login: login,
            password: password,
            completion: { [weak self] (result) in
                switch result {

                case .success(let result):
                    self?.handleSuccess(
                        walletDataModel: result.walletData,
                        keyPairs: result.keyPairs,
                        network: network,
                        completion: completion
                    )

                case .failure(let error):
                    
                    switch error {

                    case let requestWalletError as KeyServerApi.GetWalletError:
                        switch requestWalletError {

                        case .walletShouldBeVerified(let walletId):
                            self?.onVerifyWallet(
                                walletId,
                                { [weak self] in
                                    self?.signIn(
                                        login: login,
                                        password: password,
                                        network: network,
                                        completion: completion
                                    )
                            })
                            return

                        case .tfaFailed,
                             .tfaCancelled,
                             .wrongPassword:
                            break
                        }

                    default:
                        break
                    }

                    completion(.failure(error))
                }
        })
    }

    func handleSuccess(
        walletDataModel: WalletDataModel,
        keyPairs: [ECDSA.KeyData],
        network: NetworkInfoModel,
        completion: @escaping (WalletDataProviderResult) -> Void
    ) {

        let accountNetwork = WalletDataSerializable.AccountNetworkModel(
            masterAccountId: network.masterAccountId,
            name: network.masterExchangeName,
            passphrase: network.networkParams.passphrase,
            rootUrl: flowControllerStack.apiConfigurationModel.apiEndpoint,
            storageUrl: flowControllerStack.apiConfigurationModel.storageEndpoint,
            verificationUrl: flowControllerStack.apiConfigurationModel.verificationUrl
        )

        guard let walletData = WalletDataSerializable.fromWalletData(
            walletDataModel,
            signedViaAuthenticator: false,
            network: accountNetwork
            ) else {
                completion(.failure(SignInError.failedToBuildWalletData))
                return
        }

        completion(.success(walletData, keyPairs))
    }
}

// MARK: - WalletDataProviderProtocol

extension WalletDataProvider: WalletDataProviderProtocol {

    func walletData(
        for login: String,
        password: String,
        completion: @escaping (WalletDataProviderResult) -> Void
    ) {

        fetchNetworkInfo(
            login: login,
            password: password,
            completion: completion
        )
    }
}
