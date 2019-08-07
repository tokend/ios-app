import UIKit
import RxSwift

enum SaleDetails {
    
    // MARK: - Typealiases
    
    typealias SaleIdentifier = String
    typealias CellIdentifier = String
    
    // MARK: -
    
    enum Model {}
    enum Event {}
}

// MARK: - Models

extension SaleDetails.Model {
    class SceneModel {
        var sections: [SectionModel]
        var inputAmount: Decimal
        var selectedBalance: BalanceDetails?
        var chartsPeriods: [Period]
        var selectedChartsPeriod: Period?
        var selectedChartEntryIndex: Int?
        
        init() {
            self.sections = []
            self.inputAmount = 0.0
            self.selectedBalance = nil
            self.chartsPeriods = []
            self.selectedChartsPeriod = nil
            self.selectedChartEntryIndex = nil
        }
        
        init(
            sections: [SectionModel],
            inputAmount: Decimal,
            selectedBalance: BalanceDetails?,
            chartsPeriods: [Period],
            selectedChartsPeriod: Period?,
            selectedChartEntryIndex: Int?
            ) {
            
            self.sections = sections
            self.inputAmount = inputAmount
            self.selectedBalance = selectedBalance
            self.chartsPeriods = chartsPeriods
            self.selectedChartsPeriod = selectedChartsPeriod
            self.selectedChartEntryIndex = selectedChartEntryIndex
        }
    }
    
    struct SaleModel {
        let baseAsset: String
        let currentCap: Decimal
        let defaultQuoteAsset: String
        let details: Details
        let endTime: Date
        let id: String
        let investorsCount: Int
        let quoteAssets: [QuoteAsset]
        let type: SaleType
        let softCap: Decimal
        let startTime: Date
    }
    
    struct SectionModel {
        let cells: [CellModel]
    }
    
    struct CellModel {
        let cellType: CellType
    }
    
    struct SectionViewModel {
        var cells: [CellViewAnyModel]
    }
    
    enum CellType {
        case description(DescriptionCellModel)
        case investing(InvestingCellModel)
        case chart(ChartCellModel)
    }
    
    struct DescriptionCellModel {
        let imageUrl: URL?
        let name: String
        let description: String
        let asset: String
        
        let investmentAsset: String
        let investmentAmount: Decimal
        let investmentPercentage: Float
        let investorsCount: Int
        
        let startDate: Date
        let endDate: Date
        
        let youtubeVideoUrl: URL?
        
        let cellIdentifier: SaleDetails.CellIdentifier
    }
    
    struct InvestingCellModel {
        var selectedBalance: BalanceDetails?
        var amount: Decimal
        let availableAmount: Decimal
        let cellIdentifier: SaleDetails.CellIdentifier
    }
    
    struct ChartCellModel {
        let asset: String
        
        let investedAmount: Decimal
        let investedDate: Date?
        
        let datePickerItems: [Period]
        let selectedDatePickerItem: Int?
        
        let growth: Decimal
        let growthPositive: Bool?
        let growthSincePeriod: Period?
        
        let chartModel: ChartModel
        
        let cellIdentifier: SaleDetails.CellIdentifier
    }
    
    struct SaleInvestModel {
        let baseAsset: String
        let quoteAsset: String
        let baseBalance: String
        let quoteBalance: String
        let isBuy: Bool
        let baseAmount: Decimal
        let quoteAmount: Decimal
        let price: Decimal
        let fee: Decimal
        let type: Int
        let offerId: UInt64
        let prevOfferId: UInt64?
        let orderBookId: UInt64
    }
    
    struct SaleInfoModel {
        let saleId: String
        let blobId: String
        let asset: String
    }
    
    struct AssetModel {
        let logoUrl: URL?
        let verificationRequired: Bool
    }
    
    struct BalanceDetails {
        let asset: String
        let balance: Decimal
        let balanceId: String
    }
    
    struct AccountModel {
        let isVerified: Bool
    }
    
    struct BalanceDetailsViewModel {
        let asset: String
        let balance: String
        let balanceId: String
    }
    
    struct InvestmentOffer {
        let amount: Decimal
        let asset: String
        let id: UInt64
    }
    
    enum Period: Int, Hashable, Equatable {
        case hour
        case day
        case week
        case month
        case year
        
        init?(string: String) {
            switch string {
            case "hour": self.init(rawValue: Period.hour.rawValue)
            case "day": self.init(rawValue: Period.day.rawValue)
            case "week": self.init(rawValue: Period.week.rawValue)
            case "month": self.init(rawValue: Period.month.rawValue)
            case "year": self.init(rawValue: Period.year.rawValue)
            default: return nil
            }
        }
    }
    
    struct PeriodViewModel {
        let title: String
        let isEnabled: Bool
        let period: Period
    }
    
    struct ChartModel {
        let entries: [ChartEntry]
        let maxValue: Decimal
    }
    
    struct ChartEntry {
        let date: Date
        let value: Decimal
    }
    
    struct ChartViewModel {
        let entries: [ChartDataEntry]
        let maxValue: Double
        let formattedMaxValue: String
    }
    
    struct ChartDataEntry {
        let x: Double
        let y: Double
    }
    
    struct AxisFormatters {
        let xAxisFormatter: (Double) -> String
        let yAxisFormatter: (Double) -> String
    }
}

// MARK: - Events

extension SaleDetails.Event {
    typealias Model = SaleDetails.Model
    
    enum ViewDidLoad {
        struct Request {}
    }
    
    enum SectionsUpdated {
        struct Response {
            let sections: [Model.SectionModel]
        }
        struct ViewModel {
            let sections: [Model.SectionViewModel]
        }
    }
    
    enum SelectBalance {
        struct Request {}
        
        struct Response {
            let balances: [Model.BalanceDetails]
        }
        
        struct ViewModel {
            let balances: [Model.BalanceDetailsViewModel]
        }
    }
    
    struct BalanceSelected {
        struct Request {
            let balanceId: String
        }
        
        struct Response {
            let updatedCell: Model.InvestingCellModel
        }
        
        struct ViewModel {
            let updatedCell: SaleDetails.InvestingCell.ViewModel
        }
    }
    
    struct EditAmount {
        struct Request {
            let amount: Decimal?
        }
    }
    
    enum InvestAction {
        struct Request {}
        
        enum Response {
            case loading
            case loaded
            case failed(SaleDetails.Event.InvestAction.Response.InvestError)
            case succeeded(Model.SaleInvestModel)
        }
        
        enum ViewModel {
            case loading
            case loaded
            case failed(errorMessage: String)
            case succeeded(Model.SaleInvestModel)
        }
    }
    
    enum DidSelectMoreInfoButton {
        struct Request {}
        
        struct Response {
            let saleId: String
            let blobId: String
            let asset: String
        }
        
        struct ViewModel {
            let saleId: String
            let blobId: String
            let asset: String
        }
    }
    
    enum SelectChartPeriod {
        struct Request {
            let period: Int
        }
        
        struct Response {
            let asset: String
            
            let periods: [Model.Period]
            let selectedPeriod: Model.Period
            let selectedPeriodIndex: Int?
            
            let growth: Decimal
            let growthPositive: Bool?
            let growthSincePeriod: Model.Period?
            
            let chartModel: Model.ChartModel
            
            let updatedCell: Model.ChartCellModel
        }
        
        struct ViewModel {
            let viewModel: SaleDetails.ChartCell.ChartUpdatedViewModel
            let updatedCell: SaleDetails.ChartCell.ViewModel
        }
    }
    
    enum SelectChartEntry {
        struct Request {
            let chartEntryIndex: Int?
        }
        
        struct Response {
            let asset: String
            let investedAmount: Decimal
            let investedDate: Date?
            let identifier: SaleDetails.CellIdentifier
        }
        
        struct ViewModel {
            let viewModel: SaleDetails.ChartCell.ChartEntrySelectedViewModel
        }
    }
}

// MARK: -

extension SaleDetails.Model.DescriptionCellModel {
    enum ImageState {
        case empty
        case loaded(UIImage)
        case loading
    }
}

extension SaleDetails.Model.SaleModel {
    struct Details {
        let description: String
        let logoUrl: URL?
        let name: String
        let shortDescription: String
        let youtubeVideoUrl: URL?
    }
    
    struct QuoteAsset {
        let asset: String
        let currentCap: Decimal
        let price: Decimal
        let quoteBalanceId: String
    }
    
    enum SaleType: Int {
        case basic = 1
        case crowdFunding = 2
        case fixedPrice = 3
    }
}

extension SaleDetails.Model.BalanceDetails: Equatable {
    static func ==(left: SaleDetails.Model.BalanceDetails, right: SaleDetails.Model.BalanceDetails) -> Bool {
        return (left.asset == right.asset)
            && (left.balance == right.balance)
            && (left.balanceId == right.balanceId)
    }
}

extension SaleDetails.Event.InvestAction.Response {
    enum InvestError: Swift.Error, LocalizedError {
        case baseBalanceIsNotFound(asset: String)
        case feeError(Error)
        case formatError
        case inputIsEmpty
        case insufficientFunds
        case quoteAssetIsNotFound
        case quoteBalanceIsNotFound
        case saleIsNotFound
        
        // MARK: - LocalizedError
        
        var errorDescription: String? {
            switch self {
            case .inputIsEmpty:
                return "Empty amount"
            case .quoteBalanceIsNotFound:
                return "Quote balance is not found"
            case .quoteAssetIsNotFound:
                return "Quote asset is not found"
            case .saleIsNotFound:
                return "Sale is not found"
            case .baseBalanceIsNotFound(let asset):
                return "\(asset) balance is not created"
            case .formatError:
                return "Error while formatting orderBookId"
            case .feeError(let error):
                return "Fee error: \(error.localizedDescription)"
            case .insufficientFunds:
                return "Insufficient funds"
            }
        }
    }
}
