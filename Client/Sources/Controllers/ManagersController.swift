import Foundation
import TokenDSDK

class ManagersController {
    
    // MARK: - Public properties

    public let keychainManager: KeychainManagerProtocol
    public let userDataManager: UserDataManagerProtocol
    public let settingsManager: SettingsManagerProtocol
    public let transactionSender: TransactionSender
    public let transactionSigner: TransactionSigner
    public let transactionCreator: TransactionCreator
    public let latestChangeRoleRequestProvider: LatestChangeRoleRequestProvider
    public let precisionProvider: PrecisionProvider
    public let accountTypeManager: AccountTypeManagerProtocol
    public let accountTypeFetcher: AccountTypeFetcherProtocol
    public let notificationsRegisterer: FirebaseNotificationsRegistererProtocol?
    public let tfaManager: TFAManagerProtocol
    public private(set) lazy var accountKYCFormSender: AccountKYCFormSenderProtocol = {
        createAccountKYCFormSender()
    }()
    public private(set) lazy var imagesUtility: ImagesUtility = {
        createImagesUtility()
    }()
    public private(set) lazy var notificationsSettingsManager: NotificationsSettingsManagerProtocol = {
        createNotificationsSettingsManagerProtocol()
    }()
    public private(set) lazy var passwordChanger: PasswordChangerProtocol = {
        createPasswordChanger()
    }()
    public private(set) lazy var changeRoleRequestSender: ChangeRoleRequestSenderProtocol = {
        createChangeRoleRequestSender()
    }()
    public private(set) lazy var documentUploaderWorker: DocumentUploaderWorkerProtocol = {
        createDocumentUploaderWorker()
    }()

    public let amountConverter: AmountConverterProtocol = AmountConverter()

    // MARK: - Private properties

    private let managersControllerStack: ManagersControllerStack
    private let userDataProvider: UserDataProviderProtocol
    private let keychainDataProvider: KeychainDataProviderProtocol
    private lazy var accountKYCFormEncoder: AccountKYCFormEncoder = {
        createAccountKYCFormEncoder()
    }()
    
    // MARK: -
    
    init(
        managersControllerStack: ManagersControllerStack,
        keychainManager: KeychainManagerProtocol,
        userDataManager: UserDataManagerProtocol,
        settingsManager: SettingsManagerProtocol,
        transactionSender: TransactionSender,
        transactionSigner: TransactionSigner,
        transactionCreator: TransactionCreator,
        userDataProvider: UserDataProviderProtocol,
        keychainDataProvider: KeychainDataProviderProtocol,
        latestChangeRoleRequestProvider: LatestChangeRoleRequestProvider,
        precisionProvider: PrecisionProvider,
        accountTypeManager: AccountTypeManagerProtocol,
        accountTypeFetcher: AccountTypeFetcherProtocol,
        notificationsRegisterer: FirebaseNotificationsRegistererProtocol?,
        tfaManager: TFAManagerProtocol
        ) {

        self.managersControllerStack = managersControllerStack
        self.keychainManager = keychainManager
        self.userDataManager = userDataManager
        self.settingsManager = settingsManager
        self.transactionSender = transactionSender
        self.transactionSigner = transactionSigner
        self.transactionCreator = transactionCreator
        self.userDataProvider = userDataProvider
        self.keychainDataProvider = keychainDataProvider
        self.latestChangeRoleRequestProvider = latestChangeRoleRequestProvider
        self.precisionProvider = precisionProvider
        self.accountTypeManager = accountTypeManager
        self.accountTypeFetcher = accountTypeFetcher
        self.notificationsRegisterer = notificationsRegisterer
        self.tfaManager = tfaManager
    }
}

// MARK: - Private methods

private extension ManagersController {

    func createAccountKYCFormEncoder() -> AccountKYCFormEncoder {
        .init(
            documentUploader: documentUploaderWorker
        )
    }

    func createAccountKYCFormSender() -> AccountKYCFormSenderProtocol {
        AccountKYCFormSender(
            blobsApi: managersControllerStack.api.blobsApi,
            accountsApi: managersControllerStack.apiV3.accountsApi,
            lastChangeRoleRequestProvider: latestChangeRoleRequestProvider,
            kycFormEncoder: accountKYCFormEncoder,
            changeRoleRequestSender: changeRoleRequestSender,
            originalAccountId: userDataProvider.walletData.accountId
        )
    }

    private func createImagesUtility() -> ImagesUtility {
        let repo = ImagesUtility(
            storageUrl: managersControllerStack.storageUrl
        )
        return repo
    }

    private func createNotificationsSettingsManagerProtocol() -> NotificationsSettingsManagerProtocol {
        NotificationsSettingsManager(
            api: managersControllerStack.api,
            userDataProvider: userDataProvider
        )
    }

    private func createPasswordChanger() -> PasswordChangerProtocol! {
//        let changer = BasePasswordChanger(
//            transactionCreator: transactionCreator,
//            transactionSender: transactionSender,
//            keyServerApi: managersControllerStack.keyServerApi,
//            accountsApiV3: managersControllerStack.apiV3.accountsApi,
//            userDataProvider: userDataProvider,
//            keychainManager: keychainManager,
//            keysProvider: <#T##KeyServerAPIKeysProviderProtocol#>
//        )
//        return changer
        return nil
    }
    
    private func createChangeRoleRequestSender() -> ChangeRoleRequestSenderProtocol {
        ChangeRoleRequestSender(
            transactionCreator: transactionCreator,
            transactionSender: transactionSender,
            originalAccountId: userDataProvider.walletData.accountId
        )
    }
    
    private func createDocumentUploaderWorker() -> DocumentUploaderWorkerProtocol {
        let worker: DocumentUploaderWorker = .init(
            documentsApi: managersControllerStack.api.documentsApi,
            originalAccountId: userDataProvider.walletData.accountId
        )
        return worker
    }
}

class ManagersControllerStack {

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
