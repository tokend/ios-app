import Foundation
import TokenDSDK
import TokenDWallet

class ReposController {
    
    // MARK: - Public properties

    public private(set) lazy var assetsRepo: AssetsRepo = {
        return self.createAssetsRepo()
    }()
    public private(set) lazy var balancesRepo: BalancesRepo = {
        return self.createBalancesRepo()
    }()
    public private(set) lazy var imagesUtility: ImagesUtility = {
        return self.createImagesUtility()
    }()
    public private(set) lazy var identitiesRepo: IdentitiesRepo = {
        return self.createIdentitiesRepo()
    }()
    public private(set) lazy var accountRepo: AccountRepo = {
        return self.createAccountRepo()
    }()
    public private(set) lazy var activeKycRepo: ActiveKYCRepo = {
        return self.createActiveKYCRepo()
    }()
    public private(set) lazy var kycRepo: KYCRepo = {
        return self.createKYCRepo()
    }()
    public private(set) lazy var movementsRepo: MovementsRepo = {
        return self.createMovementsRepo()
    }()
    
    public let networkInfoRepo: NetworkInfoRepo

    // MARK: - Private properties

    private let reposControllerStack: ReposControllerStack
    private let userDataProvider: UserDataProviderProtocol
    private let keychainDataProvider: KeychainDataProviderProtocol
    private let apiConfigurationModel: APIConfigurationModel

    private let managersController: ManagersController
    
    // MARK: -
    
    public init(
        reposControllerStack: ReposControllerStack,
        networkInfoRepo: NetworkInfoRepo,
        userDataProvider: UserDataProviderProtocol,
        keychainDataProvider: KeychainDataProviderProtocol,
        apiConfigurationModel: APIConfigurationModel,
        managersController: ManagersController
        ) {
        
        self.reposControllerStack = reposControllerStack
        self.networkInfoRepo = networkInfoRepo
        self.userDataProvider = userDataProvider
        self.keychainDataProvider = keychainDataProvider
        self.apiConfigurationModel = apiConfigurationModel
        self.managersController = managersController
    }
}

// MARK: - Private methods

private extension ReposController {

    func createAccountRepo() -> AccountRepo {
        let repo = AccountRepo(
            apiV3: reposControllerStack.apiV3.accountsApi,
            originalAccountId: userDataProvider.walletData.accountId
        )
        return repo
    }

    func createActiveKYCRepo() -> ActiveKYCRepo {
        let repo = ActiveKYCRepo(
            accountRepo: accountRepo,
            blobsApi: reposControllerStack.api.blobsApi,
            latestChangeRoleRequestProvider: managersController.latestChangeRoleRequestProvider,
            activeKYCStorageManager: managersController.activeKYCStorageManager
        )
        return repo
    }

    func createKYCRepo() -> KYCRepo {
        let repo = KYCRepo(
            kycApi: reposControllerStack.apiV3.kycApi,
            accountId: userDataProvider.walletData.accountId
        )
        return repo
    }

    func createAssetsRepo() -> AssetsRepo {
        let repo = AssetsRepo(api: self.reposControllerStack.apiV3.assetsApi)
        return repo
    }

    func createBalancesRepo() -> BalancesRepo {
        let repo: BalancesRepo = .init(
            accountRepo: accountRepo,
            transactionSender: managersController.transactionSender,
            transactionCreator: managersController.transactionCreator,
            originalAccountId: userDataProvider.walletData.accountId
        )
        return repo
    }

    private func createImagesUtility() -> ImagesUtility {
        let repo = ImagesUtility(
            storageUrl: self.reposControllerStack.storageUrl
        )
        return repo
    }
    
    private func createIdentitiesRepo() -> IdentitiesRepo {
        let repo = IdentitiesRepo(
            identitiesApi: reposControllerStack.api.identitiesApi
        )
        return repo
    }

    private func createMovementsRepo() -> MovementsRepo {
        let repo = MovementsRepo(
            api: reposControllerStack.apiV3.historyApi,
            accountId: userDataProvider.walletData.accountId
        )
        return repo
    }
}

class ReposControllerStack {
    
    // MARK: - APIs
    
    let api: TokenDSDK.API
    let apiV3: TokenDSDK.APIv3
    let keyServerApi: TokenDSDK.KeyServerApi
    
    // MARK: - URLs
    
    let storageUrl: String
    
    // MARK: -
    
    init(
        api: TokenDSDK.API,
        apiV3: TokenDSDK.APIv3,
        keyServerApi: TokenDSDK.KeyServerApi,
        storageUrl: String
        ) {
        
        self.api = api
        self.apiV3 = apiV3
        self.keyServerApi = keyServerApi
        self.storageUrl = storageUrl
    }
}
