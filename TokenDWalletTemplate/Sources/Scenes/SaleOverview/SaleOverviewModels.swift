import UIKit

public enum SaleOverview {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension SaleOverview.Model {
    
    public struct SaleModel {
        
        public let baseAsset: String
        public let currentCap: Decimal
        public let defaultQuoteAsset: String
        public let details: Details
        public let endTime: Date
        public let id: String
        public let ownerId: String
        public let investorsCount: Int
        public let quoteAssets: [QuoteAsset]
        public let type: SaleType
        public let softCap: Decimal
        public let startTime: Date
        
        public init(
            baseAsset: String,
            currentCap: Decimal,
            defaultQuoteAsset: String,
            details: Details,
            endTime: Date,
            id: String,
            ownerId: String,
            investorsCount: Int,
            quoteAssets: [QuoteAsset],
            type: SaleType,
            softCap: Decimal,
            startTime: Date
            ) {
            
            self.baseAsset = baseAsset
            self.currentCap = currentCap
            self.defaultQuoteAsset = defaultQuoteAsset
            self.details = details
            self.endTime = endTime
            self.id = id
            self.ownerId = ownerId
            self.investorsCount = investorsCount
            self.quoteAssets = quoteAssets
            self.type = type
            self.softCap = softCap
            self.startTime = startTime
        }
    }
    
    public struct OverviewModel {
        
        public let imageUrl: URL?
        public let name: String
        public let description: String
        public let asset: String
        public let investmentAsset: String
        public let investmentAmount: Decimal
        public let targetAmount: Decimal
        public let investmentPercentage: Float
        public let investorsCount: Int
        public let startDate: Date
        public let endDate: Date
        public let youtubeVideoUrl: URL?
        public let overviewContent: String?
        
        public init(
            imageUrl: URL?,
            name: String,
            description: String,
            asset: String,
            investmentAsset: String,
            investmentAmount: Decimal,
            targetAmount: Decimal,
            investmentPercentage: Float,
            investorsCount: Int,
            startDate: Date,
            endDate: Date,
            youtubeVideoUrl: URL?,
            overviewContent: String?
            ) {
            
            self.imageUrl = imageUrl
            self.name = name
            self.description = description
            self.asset = asset
            self.investmentAsset = investmentAsset
            self.investmentAmount = investmentAmount
            self.targetAmount = targetAmount
            self.investmentPercentage = investmentPercentage
            self.investorsCount = investorsCount
            self.startDate = startDate
            self.endDate = endDate
            self.youtubeVideoUrl = youtubeVideoUrl
            self.overviewContent = overviewContent
        }
    }
    
    public struct OverviewViewModel {
        
        public let imageUrl: URL?
        public let name: String
        public let description: NSAttributedString
        public let youtubeVideoUrl: URL?
        public let investedAmountText: NSAttributedString
        public let targetAmountText: NSAttributedString
        public let investedPercentage: CGFloat
        public let timeText: NSAttributedString
        public let overviewContent: String?
        
        public init(
            imageUrl: URL?,
            name: String,
            description: NSAttributedString,
            youtubeVideoUrl: URL?,
            investedAmountText: NSAttributedString,
            targetAmountText: NSAttributedString,
            investedPercentage: CGFloat,
            timeText: NSAttributedString,
            overviewContent: String?
            ) {
            
            self.imageUrl = imageUrl
            self.name = name
            self.description = description
            self.youtubeVideoUrl = youtubeVideoUrl
            self.investedAmountText = investedAmountText
            self.targetAmountText = targetAmountText
            self.investedPercentage = investedPercentage
            self.timeText = timeText
            self.overviewContent = overviewContent
        }
    }
    
    public struct SaleOverviewModel {
        
        public let overview: String
        
        public init(overview: String) {
            self.overview = overview
        }
    }
}

// MARK: - Events

extension SaleOverview.Event {
    
    public typealias Model = SaleOverview.Model
    
    // MARK: -
    
    public enum ViewDidLoad {
        
        public struct Request { public init() { } }
    }
    
    public enum SaleUpdated {
        
        public struct Response {
            
            public let model: Model.OverviewModel
            
            public init(model: Model.OverviewModel) {
                self.model = model
            }
        }
        
        public struct ViewModel {
            
            public let model: Model.OverviewViewModel
            
            public init(model: Model.OverviewViewModel) {
                self.model = model
            }
        }
    }
}

// MARK: -

extension SaleOverview.Model.SaleModel {
    
    public struct Details {
        let description: String
        let logoUrl: URL?
        let name: String
        let shortDescription: String
        let youtubeVideoUrl: URL?
    }
    
    public struct QuoteAsset {
        let asset: String
        let currentCap: Decimal
        let price: Decimal
        let quoteBalanceId: String
    }
    
    public enum SaleType: Int {
        case basic = 1
        case crowdFunding = 2
        case fixedPrice = 3
    }
}
