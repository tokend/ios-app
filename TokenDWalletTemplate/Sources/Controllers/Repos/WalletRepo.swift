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
    
    private let api: TokenDSDK.KeyServerApi
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
        api: TokenDSDK.KeyServerApi,
        userDataManager: UserDataManagerProtocol,
        userDataProvider: UserDataProviderProtocol
        ) {
        
        self.api = api
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
        self.api.requestWallet(
            walletId: walletId,
            walletKDF: walletKDF,
            completion: { [weak self] (result) in
                self?.loadingStatus.accept(.loaded)
                
                switch result {
                    
                case .failure(let error):
                    self?.errorStatus.accept(error)
                    
                case .success(let walletData):
                    guard let serializable = WalletDataSerializable.fromWalletData(walletData) else {
                        return
                    }
                    
                    _ = self?.userDataManager.saveWalletData(serializable, account: account)
                    self?.wallet.accept(serializable)
                }
        })
    }
}
