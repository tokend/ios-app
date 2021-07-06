import Foundation
import TokenDSDK
import TokenDWallet
import DLCryptoKit

class RegistrationChecker {

    private let keyServerApi: KeyServerApi

    init(keyServerApi: KeyServerApi) {

        self.keyServerApi = keyServerApi
    }
}

extension RegistrationChecker: RegistrationCheckerProtocol {

    func checkIsRegistered(
        login: String,
        completion: @escaping (RegistrationCheckerIsRegisteredResult) -> Void
    ) {

        keyServerApi.getWalletKDF(
            login: login,
            isRecovery: false,
            completion: { (result) in

                switch result {

                case .success:
                    completion(.success(registered: true))

                case .failure(let error):

                    switch error {

                    case let getWalletKDFError as KeyServerApi.GetWalletKDFError:

                        switch getWalletKDFError {

                        case .loginNotFound:
                            completion(.success(registered: false))
                        }

                    default:
                        completion(.failure(error))
                    }
                }
        })
    }
}
