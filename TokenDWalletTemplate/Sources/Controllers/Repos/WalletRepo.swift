import Foundation
import RxCocoa
import RxSwift
import TokenDSDK

class WalletRepo {
    
    enum LoadingStatus {
        case loading
        case loaded
    }
    
    typealias Wallet = WalletDataSerializable
    
    // MARK: - Private properties
    
    private let generalApi: TokenDSDK.GeneralApi
    private let keyServerApi: TokenDSDK.KeyServerApi
    private let apiConfigurationModel: APIConfigurationModel
    private let userDataManager: UserDataManagerProtocol
    private let userDataProvider: UserDataProviderProtocol
    
    private let wallet: BehaviorRelay<Wallet>
    private let loadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
    private let errorStatus: PublishRelay<Swift.Error> = PublishRelay()
    
    // MARK: - Public properties
    
    public var walletValue: Wallet {
        return self.wallet.value
    }
    
    public var loadingStatusValue: LoadingStatus {
        return self.loadingStatus.value
    }
    
    // MARK: -
    
    init(
        generalApi: TokenDSDK.GeneralApi,
        keyServerApi: TokenDSDK.KeyServerApi,
        apiConfigurationModel: APIConfigurationModel,
        userDataManager: UserDataManagerProtocol,
        userDataProvider: UserDataProviderProtocol
        ) {
        
        self.generalApi = generalApi
        self.keyServerApi = keyServerApi
        self.apiConfigurationModel = apiConfigurationModel
        self.userDataManager = userDataManager
        self.userDataProvider = userDataProvider
        self.wallet = BehaviorRelay(value: userDataProvider.walletData)
    }
    
    // MARK: - Public
    
    public func observeWallet() -> Observable<Wallet> {
        return self.wallet.asObservable()
    }
    
    public func observeLoadingStatus() -> Observable<LoadingStatus> {
        return self.loadingStatus.asObservable()
    }
    
    public func observeErrorStatus() -> Observable<Swift.Error> {
        return self.errorStatus.asObservable()
    }
    
    func updateWallet() {
        guard self.loadingStatusValue == .loaded else {
            return
        }
        
        let account = self.userDataProvider.account
        let walletId = self.userDataProvider.walletData.walletId
        let walletKDF = self.userDataProvider.walletData.walletKDF.getWalletKDFParams()
        
        self.loadingStatus.accept(.loading)
        self.keyServerApi.requestWallet(
            walletId: walletId,
            walletKDF: walletKDF,
            completion: { [weak self] (result) in
                self?.loadingStatus.accept(.loaded)
                
                switch result {
                    
                case .failure(let error):
                    self?.errorStatus.accept(error)
                    
                case .success(let walletData):
                    self?.requestNetworkModel(walletData: walletData, account: account)
                }
        })
    }
    
    // MARK: - Private
    
    private func requestNetworkModel(walletData: WalletDataModel, account: String) {
        self.generalApi.requestNetworkInfo { [weak self] (result) in
            switch result {
                
            case .failed(let error):
                self?.errorStatus.accept(error)
                
            case .succeeded(let network):
                self?.saveWalletData(walletData: walletData, account: account, network: network)
            }
        }
    }
    
    private func saveWalletData(walletData: WalletDataModel, account: String, network: NetworkInfoModel) {
        let accountNetwork = WalletDataSerializable.AccountNetworkModel(
            masterAccountId: network.masterAccountId,
            name: network.masterExchangeName,
            passphrase: network.networkParams.passphrase,
            rootUrl: self.apiConfigurationModel.apiEndpoint,
            storageUrl: self.apiConfigurationModel.storageEndpoint
        )
        guard let serializable = WalletDataSerializable.fromWalletData(
            walletData,
            signedViaAuthenticator: false,
            network: accountNetwork
            ) else { return }
        
        _ = self.userDataManager.saveWalletData(serializable, account: account)
        self.wallet.accept(serializable)
    }
}
