import LocalAuthentication
import RxCocoa
import RxSwift
import UIKit

enum SalesSectionsProviderLoadingStatus {
    case loading
    case loaded
}

protocol SalesSectionsProviderProtocol {
    typealias LoadingStatus = SalesSectionsProviderLoadingStatus
    
    func observeSections() -> Observable<[Sales.Model.SectionModel]>
    func observeLoadingStatus() -> Observable<LoadingStatus>
    func observeLoadingMoreStatus() -> Observable<LoadingStatus>
    func observeErrorStatus() -> Observable<Swift.Error>
    
    func refreshSales()
    func loadMoreSales()
}

extension Sales {
    
    typealias SectionsProvider = SalesSectionsProviderProtocol
    
    class SalesSectionsProvider: SectionsProvider {
        
        // MARK: - Private properties
        
        private let salesRepo: SalesRepo
        private let imagesUtility: ImagesUtility
        
        // MARK: -
        
        init(
            salesRepo: SalesRepo,
            imagesUtility: ImagesUtility
            ) {
            
            self.salesRepo = salesRepo
            self.imagesUtility = imagesUtility
        }
        
        // MARK: - SectionsProvider
        
        func observeSections() -> Observable<[Sales.Model.SectionModel]> {
            return self.salesRepo.observeSales().map({ (sales) -> [Sales.Model.SectionModel] in
                return self.createSections(sales: sales)
            })
        }
        
        func observeLoadingStatus() -> Observable<SectionsProvider.LoadingStatus> {
            return self.salesRepo.observeLoadingStatus().map({ (status) -> SectionsProvider.LoadingStatus in
                return status.saleSectionsProviderLoadingStatus
            })
        }
        
        func observeLoadingMoreStatus() -> Observable<SalesSectionsProviderProtocol.LoadingStatus> {
            return self.salesRepo.observeLoadingMoreStatus().map({ (status) -> SectionsProvider.LoadingStatus in
                return status.saleSectionsProviderLoadingStatus
            })
        }
        
        func observeErrorStatus() -> Observable<Swift.Error> {
            return self.salesRepo.observeErrorStatus()
        }
        
        func refreshSales() {
            self.salesRepo.reloadSales()
        }
        
        func loadMoreSales() {
            self.salesRepo.loadMoreSales()
        }
        
        // MARK: - Private
        
        private func createSections(sales: [SalesRepo.Sale]) -> [Model.SectionModel] {
            let sections: [Model.SectionModel] = sales.map { (sale) -> Model.SectionModel in
                let investmentPercentage: Float
                if sale.softCap != 0.0 {
                    investmentPercentage = Float(truncating: sale.currentCap / sale.softCap as NSNumber)
                } else {
                    investmentPercentage = 1.0
                }
                
                let saleModel = Model.SaleModel(
                    imageURL: self.getImageUrl(sale: sale),
                    name: sale.details.name,
                    description: sale.details.shortDescription,
                    asset: sale.baseAsset,
                    investmentAsset: sale.defaultQuoteAsset,
                    investmentAmount: sale.currentCap,
                    investmentPercentage: investmentPercentage,
                    investorsCount: sale.statistics.investors,
                    startDate: sale.startTime,
                    endDate: sale.endTime,
                    saleIdentifier: sale.id
                )
                
                return Model.SectionModel(sales: [saleModel])
            }
            
            return sections
        }
        
        private func getImageUrl(sale: SalesRepo.Sale) -> URL? {
            let imageKey: ImagesUtility.ImageKey
            if let url = sale.details.logo.url {
                imageKey = .url(url)
            } else {
                imageKey = .key(sale.details.logo.key)
            }
            
            return self.imagesUtility.getImageURL(imageKey)
        }
    }
}

extension SalesRepo.LoadingStatus {
    var saleSectionsProviderLoadingStatus: SalesSectionsProviderProtocol.LoadingStatus {
        switch self {
            
        case .loading:
            return .loading
            
        case .loaded:
            return .loaded
        }
    }
}
