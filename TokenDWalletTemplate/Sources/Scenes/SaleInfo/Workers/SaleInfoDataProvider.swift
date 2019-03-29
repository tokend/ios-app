import Foundation
import TokenDSDK
import RxSwift
import RxCocoa

protocol SaleInfoDataProviderProtocol {
    func observeData() -> Observable<[SaleInfo.Model.TabModel]>
}

extension SaleInfo {
    typealias DataProvider = SaleInfoDataProviderProtocol
    
    class SaleInfoDataProvider: DataProvider {
        
        private let accountId: String
        private let saleId: String
        private let asset: String
        private let blobId: String
        
        private let salesApi: SalesApi
        private let blobsApi: BlobsApi
        
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
        
        init(
            accountId: String,
            saleId: String,
            blobId: String,
            asset: String,
            salesApi: SalesApi,
            blobsApi: BlobsApi,
            assetsRepo: AssetsRepo,
            imagesUtility: ImagesUtility,
            balancesRepo: BalancesRepo
            ) {
            self.accountId = accountId
            self.saleId = saleId
            self.blobId = blobId
            self.asset = asset
            self.salesApi = salesApi
            self.blobsApi = blobsApi
            self.assetsRepo = assetsRepo
            self.imagesUtility = imagesUtility
            self.balancesRepo = balancesRepo
        }
        
        func observeData() -> Observable<[SaleInfo.Model.TabModel]> {
            self.updateRelay
                .subscribe(onNext: { [weak self] (_) in
                    var tabs: [Model.TabModel] = []
                    
                    if let blob = self?.blobStatus,
                        let tab = self?.getPlainTextTab(blobStatus: blob) {
                        tabs.append(tab)
                    } else {
                        self?.addLoadingTab(to: &tabs, title: Localized(.overview))
                    }
                    
                    if let saleDetails = self?.saleDetailsStatus,
                        let tab = self?.getSaleDetailsTab(saleDetailsStatus: saleDetails) {
                        tabs.append(tab)
                    } else {
                        self?.addLoadingTab(to: &tabs, title: Localized(.general))
                    }
                    
                    if let asset = self?.assetModel,
                        let tab = self?.getAssetDetailsTab(assetStatus: asset) {
                        tabs.append(tab)
                    } else {
                        self?.addLoadingTab(to: &tabs, title: Localized(.token))
                    }
                    
                    self?.tabs.onNext(tabs)
                })
                .disposed(by: self.disposeBag)
            
            self.downloadSaleDetails()
            self.downloadBlob()
            self.observeAsset(assetCode: self.asset)
            
            return self.tabs.asObservable()
        }
        
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
        
        private func getPlainTextTab(blobStatus: BlobResponseStatus) -> Model.TabModel {
            switch blobStatus {
                
            case .failure(let error):
                let model = SaleInfo.EmptyContent.Model(message: error.localizedDescription)
                let tabModel = Model.TabModel(title: Localized(.overview), contentModel: model)
                return tabModel
                
            case .success(let blob):
                let model = SaleInfo.PlainTextContent.Model(contentText: blob.attributes.value)
                let tabModel = Model.TabModel(title: Localized(.overview), contentModel: model)
                return tabModel
            }
        }
        
        private func getSaleDetailsTab(saleDetailsStatus: SaleDetailsResponseStatus) -> Model.TabModel {
            switch saleDetailsStatus {
                
            case .failure(let error):
                let model = SaleInfo.EmptyContent.Model(message: error.localizedDescription)
                let tabModel = Model.TabModel(title: Localized(.general), contentModel: model)
                return tabModel
                
            case .success(let saleDetails):
                let model = SaleInfo.GeneralContent.Model(
                    baseAsset: saleDetails.baseAsset,
                    defaultQuoteAsset: saleDetails.defaultQuoteAsset,
                    hardCap: saleDetails.hardCap,
                    baseHardCap: saleDetails.baseHardCap,
                    softCap: saleDetails.softCap,
                    startTime: saleDetails.startTime,
                    endTime: saleDetails.endTime
                )
                let tabModel = Model.TabModel(title: Localized(.general), contentModel: model)
                
                return tabModel
            }
        }
        
        private func getAssetDetailsTab(assetStatus: AssetResponseStatus) -> Model.TabModel {
            switch assetStatus {
                
            case .failure(let error):
                let model = SaleInfo.EmptyContent.Model(message: error.localizedDescription)
                let tabModel = Model.TabModel(title: Localized(.token), contentModel: model)
                return tabModel
                
            case .success(let asset):
                var iconUrl: URL?
                
                if let key = asset.defaultDetails?.logo?.key {
                    let imageKey = ImagesUtility.ImageKey.key(key)
                    iconUrl = imagesUtility.getImageURL(imageKey)
                }
                
                var balanceState: SaleInfo.TokenContent.BalanceState = .notCreated
                let existingBalance = self.balancesRepo.balancesDetailsValue.first(where: { (balance) -> Bool in
                    return balance.asset == asset.code
                })
                if existingBalance != nil {
                    balanceState = .created
                }
                
                let model = SaleInfo.TokenContent.Model(
                    assetName: asset.defaultDetails?.name,
                    assetCode: asset.code,
                    imageUrl: iconUrl,
                    balanceState: balanceState,
                    availableTokenAmount: asset.availableForIssuance,
                    issuedTokenAmount: asset.issued,
                    maxTokenAmount: asset.maxIssuanceAmount
                )
                
                let tabModel = Model.TabModel(title: Localized(.token), contentModel: model)
                
                return tabModel
            }
        }
        
        private func addLoadingTab(to tabs: inout [Model.TabModel], title: String) {
            let contentModel = SaleInfo.LoadingContent.Model()
            let tab = Model.TabModel(
                title: title,
                contentModel: contentModel
            )
            tabs.append(tab)
        }
        
        private func downloadBlob() {
            self.blobsApi.requestBlob(
                blobId: self.blobId,
                completion: { [weak self] (result) in
                    switch result {
                        
                    case .failure(let error):
                        self?.tabsErrorStatus.accept(error)
                        self?.blobStatus = .failure(error: error)
                        
                    case .success(let blob):
                        self?.blobStatus = .success(response: blob)
                    }
                }
            )
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

extension SaleInfo.SaleInfoDataProvider {
    enum LoadingStatus {
        case loading
        case loaded
    }
    
    enum BlobResponseStatus {
        case success(response: BlobResponse)
        case failure(error: Swift.Error)
    }
    
    enum SaleDetailsResponseStatus {
        case success(response: SaleDetailsResponse)
        case failure(error: Swift.Error)
    }
    
    enum AssetResponseStatus {
        case success(response: AssetsRepo.Asset)
        case failure(error: Swift.Error)
    }
    
    enum Errors: Swift.Error, LocalizedError {
        case noToken
        
        var errorDescription: String? {
            switch self {
                
            case .noToken:
                return Localized(.no_token)
            }
        }
    }
}
