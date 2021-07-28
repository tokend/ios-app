import Foundation
import TokenDSDK
import TokenDWallet

class LocalSignInWorker {

    // MARK: - Private properties

    private let userDataManager: UserDataManagerProtocol
    private let keychainManager: KeychainManagerProtocol

    // MARK: -

    /// Initializer
    /// - Parameters:
    ///   - login: this is email or phone number, depending on what is used to log in
    ///   - userDataManager: user data manager.
    ///   - keychainManager: keychain manager.
    init(
        userDataManager: UserDataManagerProtocol,
        keychainManager: KeychainManagerProtocol
        ) {

        self.userDataManager = userDataManager
        self.keychainManager = keychainManager
    }
}

extension LocalSignInWorker: LocalSignInWorkerProtocol {

    func performSignIn(
        login: String,
        passcode: String,
        completion: @escaping (SignInResult) -> Void
    ) {

        guard let walletData = self.userDataManager.getWalletData(account: login) else {
            completion(.error(error: .noSavedAccount))
            return
        }

        let walletKDF = walletData.walletKDF.getWalletKDFParams()

        let checkedLogin = walletKDF.kdfParams.checkedLogin(login)

        do {
            guard let derivedKey = try KeyPairBuilder.getKeyPairs(
                forLogin: checkedLogin,
                password: passcode,
                keychainData: walletData.keychainData,
                walletKDF: walletKDF
            ).first
                else {
                    completion(.error(error: .wrongPasscode))
                    return
            }

            if self.keychainManager.validateDerivedKeyData([derivedKey], account: login) {
                completion(.success(login: login))
            } else {
                completion(.error(error: .wrongPasscode))
            }
        } catch {
            completion(.error(error: .wrongPasscode))
        }
    }
}

