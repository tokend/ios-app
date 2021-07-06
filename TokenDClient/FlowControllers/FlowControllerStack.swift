import Foundation
import TokenDSDK

class FlowControllerStack {
    
    // MARK: - APIs
    
    var api: TokenDSDK.API
    var apiV3: TokenDSDK.APIv3
    var verifyApi: TokenDSDK.TFAVerifyApi
    var keyServerApi: TokenDSDK.KeyServerApi
    
    var network: NetworkProtocol
    
    var apiConfigurationModel: APIConfigurationModel
    var tfaDataProvider: TFADataProviderProtocol
    var networkInfoFetcher: NetworkInfoFetcher
    var precisionProvider: PrecisionProvider
    var networkInfoRepo: NetworkInfoRepo
    var settingsManager: SettingsManagerProtocol
    
    // MARK: -
    
    init(
        apiConfigurationModel: APIConfigurationModel,
        tfaDataProvider: TFADataProviderProtocol,
        network: NetworkProtocol,
        networkV3: JSONAPI.NetworkProtocol,
        apiCallbacks: ApiCallbacks,
        apiCallbacksV3: JSONAPI.ApiCallbacks,
        keyDataProvider: RequestSignKeyDataProviderProtocol,
        accountIdProvider: RequestSignAccountIdProviderProtocol,
        settingsManager: SettingsManagerProtocol
        ) {
        
        let apiConfiguration = ApiConfiguration(
            urlString: apiConfigurationModel.apiEndpoint
        )
        
        let requestSigner = RequestSigner(
            keyDataProvider: keyDataProvider,
            accountIdProvider: accountIdProvider
        )
        let requestSignerV3 = JSONAPI.RequestSigner(
            keyDataProvider: keyDataProvider,
            accountIdProvider: accountIdProvider
        )
        
        let api = TokenDSDK.API(
            configuration: apiConfiguration,
            callbacks: apiCallbacks,
            network: network,
            requestSigner: requestSigner
        )
        
        let apiV3 = TokenDSDK.APIv3(
            configuration: apiConfiguration,
            callbacks: apiCallbacksV3,
            network: networkV3,
            requestSigner: requestSignerV3
        )
        
        let verifyApi = TokenDSDK.TFAVerifyApi(
            apiConfiguration: apiConfiguration,
            requestSigner: requestSigner,
            network: network
        )
        
        let keyServerApi = KeyServerApi(
            apiConfiguration: apiConfiguration,
            callbacks: apiCallbacks,
            verifyApi: verifyApi,
            requestSigner: requestSignerV3,
            network: network,
            networkV3: networkV3
        )
        
        self.networkInfoRepo = NetworkInfoRepo(api: apiV3.infoApi)
        
        self.api = api
        self.apiV3 = apiV3
        self.verifyApi = verifyApi
        self.keyServerApi = keyServerApi
        self.network = network
        self.apiConfigurationModel = apiConfigurationModel
        self.tfaDataProvider = tfaDataProvider
        self.networkInfoFetcher = networkInfoRepo
        self.precisionProvider = networkInfoRepo
        self.settingsManager = settingsManager
    }
    
    func updateWith(
        apiConfigurationModel: APIConfigurationModel,
        tfaDataProvider: TFADataProviderProtocol,
        network: NetworkProtocol,
        networkV3: JSONAPI.NetworkProtocol,
        apiCallbacks: ApiCallbacks,
        apiCallbacksV3: JSONAPI.ApiCallbacks,
        keyDataProvider: RequestSignKeyDataProviderProtocol,
        accountIdProvider: RequestSignAccountIdProviderProtocol,
        settingsManager: SettingsManagerProtocol
        ) {
        
        let apiConfiguration = ApiConfiguration(
            urlString: apiConfigurationModel.apiEndpoint
        )
        
        let requestSigner = RequestSigner(
            keyDataProvider: keyDataProvider,
            accountIdProvider: accountIdProvider
        )
        let requestSignerV3 = JSONAPI.RequestSigner(
            keyDataProvider: keyDataProvider,
            accountIdProvider: accountIdProvider
        )
        
        let api = TokenDSDK.API(
            configuration: apiConfiguration,
            callbacks: apiCallbacks,
            network: network,
            requestSigner: requestSigner
        )
        
        let apiV3 = TokenDSDK.APIv3(
            configuration: apiConfiguration,
            callbacks: apiCallbacksV3,
            network: networkV3,
            requestSigner: requestSignerV3
        )
        
        let verifyApi = TokenDSDK.TFAVerifyApi(
            apiConfiguration: apiConfiguration,
            requestSigner: requestSigner,
            network: network
        )
        
        let keyServerApi = KeyServerApi(
            apiConfiguration: apiConfiguration,
            callbacks: apiCallbacks,
            verifyApi: verifyApi,
            requestSigner: requestSignerV3,
            network: network,
            networkV3: networkV3
        )
        
        let networkInfoRepo = NetworkInfoRepo(api: apiV3.infoApi)
        
        self.api = api
        self.apiV3 = apiV3
        self.verifyApi = verifyApi
        self.keyServerApi = keyServerApi
        self.network = network
        self.apiConfigurationModel = apiConfigurationModel
        self.tfaDataProvider = tfaDataProvider
        self.networkInfoFetcher = networkInfoRepo
        self.settingsManager = settingsManager
    }
}
