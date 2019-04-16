import UIKit
import LocalAuthentication
import RxSwift
import RxCocoa
import TokenDSDK

enum SaleDetailsDataProviderImageKey {
    case url(String)
    case key(String)
}

protocol SaleDetailsDataProviderProtocol {
    typealias ImageKey = SaleDetailsDataProviderImageKey
    
    func observeSale() -> Observable<SaleDetails.Model.SaleModel?>
    func observeAsset(assetCode: String) -> Observable<SaleDetails.Model.AssetModel?>
    func observeOverview(blobId: String) -> Observable<SaleDetails.Model.SaleOverviewModel?>
    func observeBalances() -> Observable<[SaleDetails.Model.BalanceDetails]>
    func observeAccount() -> Observable<SaleDetails.Model.AccountModel>
    func observeOffers() -> Observable<[SaleDetails.Model.InvestmentOffer]>
    func observeCharts() -> Observable<[SaleDetails.Model.Period: [SaleDetails.Model.ChartEntry]]>
    func observeErrors() -> Observable<[SaleDetails.TabIdentifier: String]>
}

extension SaleDetails {
    
    typealias DataProvider = SaleDetailsDataProviderProtocol
    
    class SaleDataProvider: DataProvider {
        
        private typealias ChartPeriod = SaleDetails.Model.Period
        private typealias ChartEntry = SaleDetails.Model.ChartEntry
        private typealias TabIdentifier = SaleDetails.TabIdentifier
        
        // MARK: - Private properties
        
        private let saleIdentifier: String
        private let salesRepo: SalesRepo
        private let assetsRepo: AssetsRepo
        private let balancesRepo: BalancesRepo
        private let walletRepo: WalletRepo
        private let offersRepo: PendingOffersRepo
        private let chartsApi: ChartsApi
        private let blobsApi: BlobsApi
        private let imagesUtility: ImagesUtility
        
        private let pendingOffers: BehaviorRelay<[PendingOffersRepo.Offer]> = BehaviorRelay(value: [])
        private let saleOverview: BehaviorRelay<Model.SaleOverviewModel?> = BehaviorRelay(value: nil)
        private let charts: BehaviorRelay<TokenDSDK.ChartsResponse> = BehaviorRelay(value: [:])
        private let errors: BehaviorRelay<[TabIdentifier: String]> = BehaviorRelay(value: [:])
        
        private var errorsValue: [TabIdentifier: String] = [:] {
            didSet {
                self.errors.accept(self.errorsValue)
            }
        }
        
        // MARK: -
        
        init(
            saleIdentifier: String,
            salesRepo: SalesRepo,
            assetsRepo: AssetsRepo,
            balancesRepo: BalancesRepo,
            walletRepo: WalletRepo,
            offersRepo: PendingOffersRepo,
            chartsApi: ChartsApi,
            blobsApi: BlobsApi,
            imagesUtility: ImagesUtility
            ) {
            
            self.saleIdentifier = saleIdentifier
            self.salesRepo = salesRepo
            self.assetsRepo = assetsRepo
            self.balancesRepo = balancesRepo
            self.walletRepo = walletRepo
            self.offersRepo = offersRepo
            self.chartsApi = chartsApi
            self.blobsApi = blobsApi
            self.imagesUtility = imagesUtility
        }
        
        // MARK: - SectionsProvider
        
        func observeSale() -> Observable<Model.SaleModel?> {
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
                    investorsCount: sale.statistics.investors,
                    quoteAssets: quoteAssets,
                    type: type,
                    softCap: sale.softCap,
                    startTime: sale.startTime
                )
                
                self?.loadPendingOffers(saleId: saleModel.id)
                self?.loadCharts(saleAsset: sale.baseAsset)
                
                return saleModel
            })
        }
        
        func observeAsset(assetCode: String) -> Observable<Model.AssetModel?> {
            return self.assetsRepo.observeAsset(code: assetCode).map({ (asset) -> Model.AssetModel? in
                guard let asset = asset else {
                    return nil
                }
                
                let logo = Logo(
                    key: asset.defaultDetails?.logo?.key,
                    url: asset.defaultDetails?.logo?.url
                )
                let assetModel = Model.AssetModel(
                    logoUrl: self.logoUrl(logo)
                )
                
                return assetModel
            })
        }
        
        func observeOverview(blobId: String) -> Observable<SaleDetails.Model.SaleOverviewModel?> {
            self.loadOverview(blobId: blobId)
            return self.saleOverview.asObservable()
        }
        
        func observeBalances() -> Observable<[Model.BalanceDetails]> {
            return self.balancesRepo.observeBalancesDetails().map { (balances) -> [Model.BalanceDetails] in
                return balances.compactMap({ (balanceState) -> BalancesRepo.BalanceDetails? in
                    switch balanceState {
                        
                    case .creating:
                        return nil
                        
                    case .created(let balance):
                        return balance
                    }
                }).map({ (balance) -> Model.BalanceDetails in
                    return Model.BalanceDetails(
                        asset: balance.asset,
                        balance: balance.balance,
                        balanceId: balance.balanceId,
                        prevOfferId: nil
                    )
                })
            }
        }
        
        func observeAccount() -> Observable<Model.AccountModel> {
            return self.walletRepo.observeWallet().map({ (walletData) -> Model.AccountModel in
                return Model.AccountModel(isVerified: walletData.verified)
            })
        }
        
        func observeCharts() -> Observable<[Model.Period: [Model.ChartEntry]]> {
            return self.charts.map({ (chartsResponse) -> [Model.Period: [Model.ChartEntry]] in
                var charts = [Model.Period: [Model.ChartEntry]]()
                for key in chartsResponse.keys {
                    guard let period = Model.Period(string: key),
                        let chart = chartsResponse[key]
                        else {
                            continue
                    }
                    
                    charts[period] = chart.map({ (chart) -> Model.ChartEntry in
                        return chart.chart
                    })
                }
                
                return charts
            })
        }
        
        func observeOffers() -> Observable<[Model.InvestmentOffer]> {
            self.loadPendingOffers(saleId: self.saleIdentifier)
            
            return self.pendingOffers.map({ (offers) -> [Model.InvestmentOffer] in
                return offers.map({ (offer) -> Model.InvestmentOffer in
                    return Model.InvestmentOffer(
                        amount: offer.quoteAmount,
                        asset: offer.quoteAssetCode,
                        id: offer.offerId
                    )
                })
            }).asObservable()
        }
        
        func observeErrors() -> Observable<[SaleDetails.TabIdentifier: String]> {
            return self.errors.asObservable()
        }
        
        // MARK: - Private
        
        private func loadPendingOffers(saleId: String) {
            let parameters = OffersOffersRequestParameters(
                isBuy: true,
                order: nil,
                baseAsset: nil,
                quoteAsset: nil,
                orderBookId: saleId,
                offerId: nil
            )
            
            self.offersRepo.loadOffers(
                parameters: parameters,
                completion: { [weak self] (result) in
                    switch result {
                        
                    case .failure(let error):
                        self?.errorsValue[.investing] = error.localizedDescription
                        
                    case .success(let offers):
                        self?.pendingOffers.accept(offers)
                    }
            })
        }
        
        private func loadOverview(blobId: String) {
            self.blobsApi.requestBlob(
                blobId: blobId,
                completion: { [weak self] (result) in
                    switch result {
                        
                    case .failure(let error):
                        self?.errorsValue[.overview] = error.localizedDescription
                        
                    case .success(let blob):
                        let model = Model.SaleOverviewModel(
                            overview: blob.attributes.value
                        )
                        self?.saleOverview.accept(model)
                    }
                }
            )
        }
        
        private func loadCharts(saleAsset: String) {
            self.chartsApi.requestCharts(
                asset: saleAsset,
                completion: { [weak self] (result) in
                    switch result {
                        
                    case .failure(let error):
                        self?.errorsValue[.chart] = error.localizedDescription
                        
                    case .success(let charts):
                        self?.charts.accept(charts)
                    }
            })
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
            guard let id = id
                else {
                    return nil
            }
            
            let urlString = "https://www.youtube.com/embed/\(id)?rel=0"
            return URL(string: urlString)
        }
    }
}

// MARK: -

extension SaleDetails.DataProvider.ImageKey {
    var repoImageKey: ImagesUtility.ImageKey {
        switch self {
            
        case .key(let key):
            return .key(key)
            
        case .url(let url):
            return .url(url)
        }
    }
}

private extension TokenDSDK.ChartResponse {
    typealias Chart = SaleDetails.Model.ChartEntry
    
    var chart: Chart {
        return Chart(
            date: self.timestamp,
            value: self.value
        )
    }
}
