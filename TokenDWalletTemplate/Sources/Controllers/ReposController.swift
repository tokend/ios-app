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
    
    private var transactionsRepos: [String: TransactionsRepo] = [:]
    private let reposControllerStack: ReposControllerStack
    private let userDataProvider: UserDataProviderProtocol
    private let keychainDataProvider: KeychainDataProviderProtocol
    private let originalAccountId: String
    
    // MARK: -
    
    public init(
        reposControllerStack: ReposControllerStack,
        accountRepo: AccountRepo,
        balancesRepo: BalancesRepo,
        networkInfoRepo: NetworkInfoRepo,
        userDataProvider: UserDataProviderProtocol,
        keychainDataProvider: KeychainDataProviderProtocol,
        originalAccountId: String
        ) {
        
        self.reposControllerStack = reposControllerStack
        self.accountRepo = accountRepo
        self.balancesRepo = balancesRepo
        self.networkInfoRepo = networkInfoRepo
        self.userDataProvider = userDataProvider
        self.keychainDataProvider = keychainDataProvider
        self.originalAccountId = originalAccountId
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
            api: self.reposControllerStack.keyServerApi,
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
    
    private func createTransactionsRepoForAsset(
        _ asset: String
        ) -> TransactionsRepo {
        
        let repo = TransactionsRepo(
            api: self.reposControllerStack.api.transactionsApi,
            asset: asset,
            originalAccountId: self.originalAccountId
        )
        return repo
    }
    
    // MARK: - Public
    
    public func transactionsRepoForAsset(_ asset: String) -> TransactionsRepo {
        guard let repo = self.transactionsRepos[asset]
            else {
                self.transactionsRepos[asset] = self.createTransactionsRepoForAsset(asset)
                return self.transactionsRepoForAsset(asset)
        }
        return repo
    }
}

class ReposControllerStack {
    
    // MARK: - APIs
    
    let api: TokenDSDK.API
    let keyServerApi: TokenDSDK.KeyServerApi
    
    // MARK: - URLs
    
    let storageUrl: String
    
    // MARK: -
    
    init(
        api: TokenDSDK.API,
        keyServerApi: TokenDSDK.KeyServerApi,
        storageUrl: String
        ) {
        
        self.api = api
        self.keyServerApi = keyServerApi
        self.storageUrl = storageUrl
    }
}
