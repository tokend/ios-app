import Foundation
import TokenDSDK
import TokenDWallet

class ReposController {
    
    // MARK: - Public properties
    
    public private(set) lazy var assetsRepo: AssetsRepo = {
        return self.createAssetsRepo()
    }()
    public private(set) lazy var assetPairsRepo: AssetPairsRepo = {
        return self.createAssetPairsRepo()
    }()
    public private(set) lazy var movementsRepo: MovementsRepo = {
        return self.createMovementsRepo()
    }()
    public private(set) lazy var pendingOffersRepo: PendingOffersRepo = {
        return self.createPendingOffersRepo()
    }()
    public private(set) lazy var salesRepo: SalesRepo = {
        return self.createSalesRepo()
    }()
    public private(set) lazy var walletRepo: WalletRepo = {
        return self.createWalletRepo()
    }()
    public private(set) lazy var imagesUtility: ImagesUtility = {
        return self.createImagesUtility()
    }()
    
    public let accountRepo: AccountRepo
    public let balancesRepo: BalancesRepo
    public let networkInfoRepo: NetworkInfoRepo
    
    // MARK: - Private properties
    
    private var transactionsHistoryRepos: [String: TransactionsHistoryRepo] = [:]
    private var pollsRepos: [String: PollsRepo] = [:]
    private let reposControllerStack: ReposControllerStack
    private let userDataProvider: UserDataProviderProtocol
    private let keychainDataProvider: KeychainDataProviderProtocol
    private let originalAccountId: String
    private let apiConfigurationModel: APIConfigurationModel
    
    // MARK: -
    
    public init(
        reposControllerStack: ReposControllerStack,
        accountRepo: AccountRepo,
        balancesRepo: BalancesRepo,
        networkInfoRepo: NetworkInfoRepo,
        userDataProvider: UserDataProviderProtocol,
        keychainDataProvider: KeychainDataProviderProtocol,
        originalAccountId: String,
        apiConfigurationModel: APIConfigurationModel
        ) {
        
        self.reposControllerStack = reposControllerStack
        self.accountRepo = accountRepo
        self.balancesRepo = balancesRepo
        self.networkInfoRepo = networkInfoRepo
        self.userDataProvider = userDataProvider
        self.keychainDataProvider = keychainDataProvider
        self.originalAccountId = originalAccountId
        self.apiConfigurationModel = apiConfigurationModel
    }
    
    // MARK: -
    
    public func getTransactionsHistoryRepo(for balanceId: String) -> TransactionsHistoryRepo {
        if let transactionsHistoryRepo = self.transactionsHistoryRepos.first(where: { (key, _) -> Bool in
            return key == balanceId
        }) {
            return transactionsHistoryRepo.value
        } else {
            let transactionsHistoryRepo = TransactionsHistoryRepo(
                api: self.reposControllerStack.apiV3.historyApi,
                balanceId: balanceId
            )
            
            self.transactionsHistoryRepos[balanceId] = transactionsHistoryRepo 
            return transactionsHistoryRepo
        }
    }
    
    public func getPollsRepo(for ownerAccountId: String) -> PollsRepo {
        if let pollRepo = self.pollsRepos.first(where: { (key, _) -> Bool in
            return key == ownerAccountId
        }) {
            return pollRepo.value
        } else {
            let pollRepo = PollsRepo(
                pollsApi: self.reposControllerStack.apiV3.pollsApi,
                ownerAccountId: ownerAccountId,
                voterAccountId: self.userDataProvider.walletData.accountId
            )
            
            self.pollsRepos[ownerAccountId] = pollRepo
            return pollRepo
        }
    }
    
    // MARK: - Private
    
    private func createAssetsRepo() -> AssetsRepo {
        let repo = AssetsRepo(api: self.reposControllerStack.api)
        return repo
    }
    
    private func createAssetPairsRepo() -> AssetPairsRepo {
        let repo = AssetPairsRepo(api: self.reposControllerStack.api.assetPairsApi)
        return repo
    }
    
    private func createMovementsRepo() -> MovementsRepo {
        let repo = MovementsRepo(
            api: self.reposControllerStack.apiV3.historyApi,
            accountId: self.userDataProvider.walletData.accountId
        )
        return repo
    }
    
    private func createPendingOffersRepo() -> PendingOffersRepo {
        let repo = PendingOffersRepo(
            api: self.reposControllerStack.api.offersApi,
            originalAccountId: self.userDataProvider.walletData.accountId
        )
        return repo
    }
    
    private func createSalesRepo() -> SalesRepo {
        let repo = SalesRepo(
            api: self.reposControllerStack.api.salesApi,
            originalAccountId: self.userDataProvider.walletData.accountId
        )
        return repo
    }
    
    private func createWalletRepo() -> WalletRepo {
        let repo = WalletRepo(
            generalApi: self.reposControllerStack.api.generalApi,
            keyServerApi: self.reposControllerStack.keyServerApi,
            apiConfigurationModel: self.apiConfigurationModel,
            userDataManager: self.userDataProvider.userDataManager,
            userDataProvider: self.userDataProvider
        )
        return repo
    }
    
    private func createImagesUtility() -> ImagesUtility {
        let repo = ImagesUtility(
            storageUrl: self.reposControllerStack.storageUrl
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
