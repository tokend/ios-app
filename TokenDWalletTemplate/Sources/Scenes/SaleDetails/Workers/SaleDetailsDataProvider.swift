import Foundation
import TokenDSDK
import RxSwift
import RxCocoa

public protocol SaleDetailsDataProviderProtocol {
    
    func observeData() -> Observable<[SaleDetails.Model.TabModel]>
}

extension SaleDetails {
    
    public typealias DataProvider = SaleDetailsDataProviderProtocol
    
    public class SaleDetailsDataProvider: DataProvider {
        
        // MARK: - Private properties
        
        private let accountId: String
        private let saleId: String
        private let asset: String
        
        private let salesApi: SalesApi
        
        private let assetsRepo: AssetsRepo
        private let imagesUtility: ImagesUtility
        private let balancesRepo: BalancesRepo
        
        private let tabs: BehaviorSubject<[Model.TabModel]> = BehaviorSubject(value: [])
        private let tabsLoadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
        private let tabsErrorStatus: PublishRelay<Swift.Error> = PublishRelay()
        
        private let updateRelay: BehaviorRelay<Bool> = BehaviorRelay(value: true)
        
        private var blobStatus: BlobResponseStatus? {
            didSet {
                self.updateRelay.emitEvent()
            }
        }
        private var saleDetailsStatus: SaleDetailsResponseStatus? {
            didSet {
                self.updateRelay.emitEvent()
            }
        }
        private var assetModel: AssetResponseStatus? {
            didSet {
                self.updateRelay.emitEvent()
            }
        }
        
        private let disposeBag = DisposeBag()
        
        // MARK: -
        
        public init(
            accountId: String,
            saleId: String,
            asset: String,
            salesApi: SalesApi,
            assetsRepo: AssetsRepo,
            imagesUtility: ImagesUtility,
            balancesRepo: BalancesRepo
            ) {
            
            self.accountId = accountId
            self.saleId = saleId
            self.asset = asset
            self.salesApi = salesApi
            self.assetsRepo = assetsRepo
            self.imagesUtility = imagesUtility
            self.balancesRepo = balancesRepo
        }
        
        // MARK: - DataProvider
        
        public func observeData() -> Observable<[Model.TabModel]> {
            self.updateRelay
                .subscribe(onNext: { [weak self] (_) in
                    var tabs: [Model.TabModel] = []
                    
                    if let asset = self?.assetModel,
                        let tab = self?.getAssetDetailsTab(assetStatus: asset) {
                        tabs.append(tab)
                    } else {
                        self?.addLoadingTab(to: &tabs, title: Localized(.asset))
                    }
                    
                    if let saleDetails = self?.saleDetailsStatus,
                        let tab = self?.getSaleDetailsTab(saleDetailsStatus: saleDetails) {
                        tabs.append(tab)
                    } else {
                        self?.addLoadingTab(to: &tabs, title: Localized(.general))
                    }
                    
                    self?.tabs.onNext(tabs)
                })
                .disposed(by: self.disposeBag)
            
            self.downloadSaleDetails()
            self.observeAsset(assetCode: self.asset)
            
            return self.tabs.asObservable()
        }
        
        // MARK: - Private
        
        private func downloadSaleDetails() {
            self.tabsLoadingStatus.accept(.loading)
            
            self.salesApi.getSaleDetails(
                SaleDetailsResponse.self,
                saleId: self.saleId
            ) { [weak self] (result) in
                self?.tabsLoadingStatus.accept(.loaded)
                
                switch result {
                    
                case .failure(let error):
                    self?.tabsErrorStatus.accept(error)
                    self?.saleDetailsStatus = .failure(error: error)
                    
                case .success(let saleDetails):
                    self?.saleDetailsStatus = .success(response: saleDetails)
                }
            }
        }
        
        private func getSaleDetailsTab(saleDetailsStatus: SaleDetailsResponseStatus) -> Model.TabModel {
            switch saleDetailsStatus {
                
            case .failure(let error):
                let model = EmptyContent.Model(message: error.localizedDescription)
                let tabModel = Model.TabModel(contentModel: model)
                return tabModel
                
            case .success(let saleDetails):
                let model = GeneralContent.Model(
                    baseAsset: saleDetails.baseAsset,
                    defaultQuoteAsset: saleDetails.defaultQuoteAsset,
                    hardCap: saleDetails.hardCap,
                    baseHardCap: saleDetails.baseHardCap,
                    softCap: saleDetails.softCap,
                    startTime: saleDetails.startTime,
                    endTime: saleDetails.endTime
                )
                let tabModel = Model.TabModel(contentModel: model)
                
                return tabModel
            }
        }
        
        private func getAssetDetailsTab(assetStatus: AssetResponseStatus) -> Model.TabModel {
            switch assetStatus {
                
            case .failure(let error):
                let model = EmptyContent.Model(message: error.localizedDescription)
                let tabModel = Model.TabModel(contentModel: model)
                return tabModel
                
            case .success(let asset):
                var iconUrl: URL?
                
                if let key = asset.defaultDetails?.logo?.key {
                    let imageKey = ImagesUtility.ImageKey.key(key)
                    iconUrl = imagesUtility.getImageURL(imageKey)
                }
                
                var balanceState: TokenContent.BalanceState = .notCreated
                let existingBalance = self.balancesRepo.balancesDetailsValue.first(where: { (balance) -> Bool in
                    return balance.asset == asset.code
                })
                if existingBalance != nil {
                    balanceState = .created
                }
                
                let model = TokenContent.Model(
                    assetName: asset.defaultDetails?.name,
                    assetCode: asset.code,
                    imageUrl: iconUrl,
                    balanceState: balanceState,
                    availableTokenAmount: asset.availableForIssuance,
                    issuedTokenAmount: asset.issued,
                    maxTokenAmount: asset.maxIssuanceAmount
                )
                
                let tabModel = Model.TabModel(contentModel: model)
                
                return tabModel
            }
        }
        
        private func addLoadingTab(to tabs: inout [Model.TabModel], title: String) {
            let contentModel = LoadingContent.Model()
            let tab = Model.TabModel(contentModel: contentModel)
            tabs.append(tab)
        }
        
        private func observeAsset(assetCode: String) {
            self.assetsRepo
                .observeAsset(code: assetCode)
                .subscribe(onNext: { [weak self] (assetResponse) in
                    if let asset = assetResponse {
                        self?.assetModel = .success(response: asset)
                    } else {
                        self?.assetModel = .failure(error: Errors.noToken)
                    }
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeAssetErrorStatus() {
            self.assetsRepo
                .observeErrorStatus()
                .subscribe(onNext: { [weak self] (error) in
                    self?.assetModel = .failure(error: error)
                })
                .disposed(by: self.disposeBag)
        }
    }
}

extension SaleDetails.SaleDetailsDataProvider {
    
    public enum LoadingStatus {
        
        case loading
        case loaded
    }
    
    public enum BlobResponseStatus {
        
        case success(response: BlobResponse)
        case failure(error: Swift.Error)
    }
    
    public enum SaleDetailsResponseStatus {
        
        case success(response: SaleDetailsResponse)
        case failure(error: Swift.Error)
    }
    
    public enum AssetResponseStatus {
        
        case success(response: AssetsRepo.Asset)
        case failure(error: Swift.Error)
    }
    
    public enum Errors: Swift.Error, LocalizedError {
        
        case noToken
        
        public var errorDescription: String? {
            switch self {
                
            case .noToken:
                return Localized(.no_asset)
            }
        }
    }
}
