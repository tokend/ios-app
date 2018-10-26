import Foundation

class ManagersController {
    
    // MARK: - Public properties
    
    public private(set) lazy var externalSystemBalancesManager: ExternalSystemBalancesManager = {
        return self.createExternalSystemBalancesManager()
    }()
    public let keychainManager: KeychainManagerProtocol
    public let userDataManager: UserDataManagerProtocol
    public let settingsManager: SettingsManagerProtocol
    public let transactionSender: TransactionSender
    
    // MARK: - Private properties
    
    private let accountRepo: AccountRepo
    private let networkInfoRepo: NetworkInfoRepo
    private let userDataProvider: UserDataProviderProtocol
    
    // MARK: -
    
    init(
        accountRepo: AccountRepo,
        networkInfoRepo: NetworkInfoRepo,
        keychainManager: KeychainManagerProtocol,
        userDataManager: UserDataManagerProtocol,
        settingsManager: SettingsManagerProtocol,
        transactionSender: TransactionSender,
        userDataProvider: UserDataProviderProtocol
        ) {
        
        self.accountRepo = accountRepo
        self.networkInfoRepo = networkInfoRepo
        self.keychainManager = keychainManager
        self.userDataManager = userDataManager
        self.settingsManager = settingsManager
        self.transactionSender = transactionSender
        self.userDataProvider = userDataProvider
    }
    
    // MARK: - Private
    
    private func createExternalSystemBalancesManager() -> ExternalSystemBalancesManager {
        let manager = ExternalSystemBalancesManager(
            accountRepo: self.accountRepo,
            networkInfoFetcher: self.networkInfoRepo,
            userDataProvider: self.userDataProvider,
            transactionSender: self.transactionSender
        )
        return manager
    }
}
