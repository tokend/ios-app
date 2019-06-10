import Foundation
import RxCocoa
import RxSwift

public protocol SaleOverviewBusinessLogic {
    
    typealias Event = SaleOverview.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
}

extension SaleOverview {
    
    public typealias BusinessLogic = SaleOverviewBusinessLogic
    
    @objc(SaleOverviewInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = SaleOverview.Event
        public typealias Model = SaleOverview.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private let dataProvider: DataProvider
        
        private var saleModel: Model.SaleModel?
        private var overviewModel: Model.SaleOverviewModel?
        
        private let disposeBag = DisposeBag()
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            dataProvider: DataProvider
            ) {
            
            self.presenter = presenter
            self.dataProvider = dataProvider
        }
        
        // MARK: - Private
        
        private func observeSale() {
            self.dataProvider.observeSale()
                .subscribe(onNext: { [weak self] (sale) in
                    self?.saleModel = sale
                    
                    self?.onSaleUpdated()
                    
                    self?.observeOverview()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func observeOverview() {
            guard let blobId = self.saleModel?.details.description else {
                return
            }
            
            self.dataProvider
                .observeOverview(blobId: blobId)
                .subscribe(onNext: { [weak self] (model) in
                    self?.overviewModel = model
                    
                    self?.onSaleUpdated()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func onSaleUpdated() {
            guard let sale = self.saleModel else {
                return
            }
            
            var investmentPercentage: Float
            if sale.softCap != 0.0 {
                investmentPercentage = Float(truncating: sale.currentCap / sale.softCap as NSNumber) * 100
                if investmentPercentage > 1 {
                    investmentPercentage.round()
                }
            } else {
                investmentPercentage = 100.0
            }

            let overviewModel = Model.OverviewModel(
                imageUrl: sale.details.logoUrl,
                name: sale.details.name,
                description: sale.details.shortDescription,
                asset: sale.baseAsset,
                investmentAsset: sale.defaultQuoteAsset,
                investmentAmount: sale.currentCap,
                targetAmount: sale.softCap,
                investmentPercentage: investmentPercentage,
                investorsCount: sale.investorsCount,
                startDate: sale.startTime,
                endDate: sale.endTime,
                youtubeVideoUrl: sale.details.youtubeVideoUrl,
                overviewContent: self.overviewModel?.overview
            )
            
            let response = Event.SaleUpdated.Response(model: overviewModel)
            self.presenter.presentSaleUpdated(response: response)
        }
    }
}

extension SaleOverview.Interactor: SaleOverview.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        self.observeSale()
    }
}
