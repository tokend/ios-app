import Foundation

class SignOutWorker {

    // MARK: - Private properties

    private let userDataManager: UserDataManagerProtocol
    private let keychainManager: KeychainManagerProtocol

    // MARK: -

    init(
        userDataManager: UserDataManagerProtocol,
        keychainManager: KeychainManagerProtocol
        ) {

        self.userDataManager = userDataManager
        self.keychainManager = keychainManager
    }
}

extension SignOutWorker: SignOutWorkerProtocol {

    func performSignOut(_ completion: @escaping () -> Void) {
        userDataManager.clearAllData()
        keychainManager.clearAllData()

        completion()
    }
}
