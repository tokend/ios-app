import UIKit
import RxSwift
import RxCocoa
import TokenDSDK

public enum SaleOverviewDataProviderImageKey {
    
    case url(String)
    case key(String)
}

public protocol SaleOverviewDataProviderProtocol {
    
    typealias Model = SaleOverview.Model
    typealias ImageKey = SaleOverviewDataProviderImageKey
    
    func observeSale() -> Observable<Model.SaleModel?>
    func observeOverview(blobId: String) -> Observable<Model.SaleOverviewModel?>
    func observeErrors() -> Observable<Swift.Error?>
}

extension SaleOverview {
    
    public typealias DataProvider = SaleOverviewDataProviderProtocol
    
    public class OverviewDataProvider: DataProvider {
        
        // MARK: - Private properties
        
        private let saleIdentifier: String
        private let salesRepo: SalesRepo
        private let blobsApi: BlobsApi
        private let imagesUtility: ImagesUtility
        
        private let saleOverview: BehaviorRelay<Model.SaleOverviewModel?> = BehaviorRelay(value: nil)
        private let errors: BehaviorRelay<Swift.Error?> = BehaviorRelay(value: nil)
        
        // MARK: -
        
        public init(
            saleIdentifier: String,
            salesRepo: SalesRepo,
            blobsApi: BlobsApi,
            imagesUtility: ImagesUtility
            ) {
            
            self.saleIdentifier = saleIdentifier
            self.salesRepo = salesRepo
            self.blobsApi = blobsApi
            self.imagesUtility = imagesUtility
        }
        
        // MARK: - SectionsProvider
        
        public func observeSale() -> Observable<Model.SaleModel?> {
            return self.salesRepo.observeSale(id: self.saleIdentifier).map({ [weak self] (sale) -> Model.SaleModel? in
                guard let sale = sale else {
                    return nil
                }
                
                let quoteAssets: [Model.SaleModel.QuoteAsset] = sale.quoteAssets.quoteAssets.map({ quoteAsset in
                    return Model.SaleModel.QuoteAsset(
                        asset: quoteAsset.asset,
                        currentCap: quoteAsset.currentCap,
                        price: quoteAsset.price,
                        quoteBalanceId: quoteAsset.quoteBalanceId
                    )
                })
                
                let youtubeVideoUrl = self?.youtubeVideoUrlForId(sale.details.youtubeVideoId)
                
                let logo = Logo(
                    key: sale.details.logo.key,
                    url: sale.details.logo.url
                )
                let details = Model.SaleModel.Details(
                    description: sale.details.description,
                    logoUrl: self?.logoUrl(logo),
                    name: sale.details.name,
                    shortDescription: sale.details.shortDescription,
                    youtubeVideoUrl: youtubeVideoUrl
                )
                
                guard let type = Model.SaleModel.SaleType(rawValue: sale.saleType.value) else {
                    return nil
                }
                
                let saleModel = Model.SaleModel(
                    baseAsset: sale.baseAsset,
                    currentCap: sale.currentCap,
                    defaultQuoteAsset: sale.defaultQuoteAsset,
                    details: details,
                    endTime: sale.endTime,
                    id: sale.id,
                    ownerId: sale.ownerId,
                    investorsCount: sale.statistics.investors,
                    quoteAssets: quoteAssets,
                    type: type,
                    softCap: sale.softCap,
                    startTime: sale.startTime
                )
                
                return saleModel
            })
        }
        
        public func observeOverview(blobId: String) -> Observable<Model.SaleOverviewModel?> {
            self.loadOverview(blobId: blobId)
            return self.saleOverview.asObservable()
        }
        
        public func observeErrors() -> Observable<Swift.Error?> {
            return self.errors.asObservable()
        }
        
        // MARK: - Private
        
        private func loadOverview(blobId: String) {
            self.blobsApi.requestBlob(
                blobId: blobId,
                completion: { [weak self] (result) in
                    switch result {
                        
                    case .failure(let error):
                        self?.errors.accept(error)
                        
                    case .success(let blob):
                        let model = Model.SaleOverviewModel(
                            overview: blob.attributes.value
                        )
                        self?.saleOverview.accept(model)
                    }
                }
            )
        }
        
        private struct Logo {
            let key: String?
            let url: String?
        }
        private func logoUrl(_ logo: Logo) -> URL? {
            var imageKey: ImageKey?
            
            if let key = logo.key {
                imageKey = .key(key)
            } else if let url = logo.url {
                imageKey = .url(url)
            }
            
            if let key = imageKey?.repoImageKey {
                return self.imagesUtility.getImageURL(key)
            }
            return nil
        }
        
        private func youtubeVideoUrlForId(_ id: String?) -> URL? {
            guard let id = id,
                !id.isEmpty
                else {
                    return nil
            }
            
            let urlString = "https://www.youtube.com/embed/\(id)?rel=0"
            return URL(string: urlString)
        }
    }
}

// MARK: -

extension SaleOverview.DataProvider.ImageKey {
    
    fileprivate var repoImageKey: ImagesUtility.ImageKey {
        switch self {
            
        case .key(let key):
            return .key(key)
            
        case .url(let url):
            return .url(url)
        }
    }
}
