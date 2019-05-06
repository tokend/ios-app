import UIKit
import RxSwift

enum SaleDetails {
    
    // MARK: - Typealiases
    
    typealias SaleIdentifier = String
    
    // MARK: -
    
    enum TabIdentifier: String {
        case empty
        case details
        case invest
        case chart
        case overview
    }
    
    enum Model {}
    enum Event {}
}

// MARK: - Models

extension SaleDetails.Model {
    
    class SceneModel {
        var tabs: [TabModel]
        var selectedTabId: SaleDetails.TabIdentifier?
        var inputAmount: Decimal
        var selectedBalance: BalanceDetails?
        var chartsPeriods: [Period]
        var selectedChartsPeriod: Period?
        var selectedChartEntryIndex: Int?
        
        init() {
            self.tabs = []
            self.selectedTabId = nil
            self.inputAmount = 0.0
            self.selectedBalance = nil
            self.chartsPeriods = []
            self.selectedChartsPeriod = nil
            self.selectedChartEntryIndex = nil
        }
        
        init(
            tabs: [TabModel],
            selectedTabId: SaleDetails.TabIdentifier?,
            inputAmount: Decimal,
            selectedBalance: BalanceDetails?,
            chartsPeriods: [Period],
            selectedChartsPeriod: Period?,
            selectedChartEntryIndex: Int?
            ) {
            
            self.tabs = tabs
            self.selectedTabId = selectedTabId
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
        let ownerId: String
        let investorsCount: Int
        let quoteAssets: [QuoteAsset]
        let type: SaleType
        let softCap: Decimal
        let startTime: Date
    }
    
    struct TabModel {
        let title: String
        let tabType: TabType
        let tabIdentifier: SaleDetails.TabIdentifier
    }
    
    struct TabViewModel {
        let title: String
        let tabContent: Any
        let tabIdentifier: SaleDetails.TabIdentifier
    }
    
    struct PickerTab {
        let title: String
        let id: SaleDetails.TabIdentifier
    }
    
    struct SectionViewModel {
        var tabs: [TabViewModel]
    }
    
    enum TabType {
        case chart(ChartTabModel)
        case empty(EmptyTabModel)
        case invest(InvestTabModel)
        case overview(OverviewTabModel)
    }
    
    enum TabContentType {
        case chart(SaleDetails.ChartTab.ViewModel)
        case empty(SaleDetails.EmptyContent.ViewModel)
        case invest(SaleDetails.InvestTab.ViewModel)
        case overview(SaleDetails.OverviewTab.ViewModel)
    }
    
    enum TabViewType {
        case chart(SaleDetails.ChartTab.View)
        case empty(SaleDetails.EmptyContent.View)
        case invest(SaleDetails.InvestTab.View)
        case overview(SaleDetails.OverviewTab.View)
    }
    
    struct OverviewTabModel {
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
        
        let overviewContent: String?
        
        let tabIdentifier: SaleDetails.TabIdentifier
    }
    
    struct InvestTabModel {
        var selectedBalance: BalanceDetails?
        var amount: Decimal
        let availableAmount: Decimal
        let isCancellable: Bool
        let actionTitle: String
        let tabIdentifier: SaleDetails.TabIdentifier
    }
    
    struct ChartTabModel {
        let asset: String
        
        let investedAmount: Decimal
        let investedDate: Date?
        
        let datePickerItems: [Period]
        let selectedDatePickerItem: Int?
        
        let growth: Decimal
        let growthPositive: Bool?
        let growthSincePeriod: Period?
        
        let chartModel: ChartModel
        
        let tabIdentifier: SaleDetails.TabIdentifier
    }
    
    struct EmptyTabModel {
        let message: String
        let tabIdentifier: SaleDetails.TabIdentifier
    }
    
    struct SaleInvestModel {
        let baseAsset: String
        let quoteAsset: String
        let baseBalance: String
        let quoteBalance: String
        let isBuy: Bool
        let baseAmount: Decimal
        let quoteAmount: Decimal
        let baseAssetName: String
        let price: Decimal
        let fee: Decimal
        let type: Int
        let offerId: UInt64
        let prevOfferId: UInt64?
        let orderBookId: UInt64
    }
    
    struct CancelInvestModel {
        let baseBalance: String
        let quoteBalance: String
        let price: Decimal
        let fee: Decimal
        let prevOfferId: UInt64
        let orderBookId: UInt64
    }
    
    struct SaleInfoModel {
        let saleId: String
        let asset: String
    }
    
    struct SaleOverviewModel {
        let overview: String
    }
    
    struct AssetModel {
        let logoUrl: URL?
    }
    
    struct BalanceDetails {
        let asset: String
        let balance: Decimal
        let balanceId: String
        var prevOfferId: UInt64?
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
    
    enum TabsUpdated {
        struct Response {
            let tabs: [Model.PickerTab]
            let selectedTabIndex: Int?
            let selectedTabType: Model.TabType
        }
        struct ViewModel {
            let tabs: [Model.PickerTab]
            let selectedTabIndex: Int?
            let selectedTabContent: Model.TabContentType
        }
    }
    
    enum TabWasSelected {
        struct Request {
            let identifier: SaleDetails.TabIdentifier
        }
        struct Response {
            let tabType: Model.TabType
        }
        struct ViewModel {
            let tabContent: Model.TabContentType
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
            let updatedTab: Model.InvestTabModel
        }
        
        struct ViewModel {
            let updatedTab: SaleDetails.InvestTab.ViewModel
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
    
    enum CancelInvestAction {
        struct Request {}
        
        enum Response {
            case loading
            case succeeded
            case failed(CancellationError)
        }
        
        enum ViewModel {
            case loading
            case succeeded
            case failed(errorMessage: String)
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
            
            let updatedTab: Model.ChartTabModel
        }
        
        struct ViewModel {
            let viewModel: SaleDetails.ChartTab.ChartUpdatedViewModel
            let updatedTab: SaleDetails.ChartTab.ViewModel
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
            let identifier: SaleDetails.TabIdentifier
        }
        
        struct ViewModel {
            let viewModel: SaleDetails.ChartTab.ChartEntrySelectedViewModel
        }
    }
}

// MARK: -

extension SaleDetails.Model.OverviewTabModel {
    
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
        case investInOwnSaleIsForbidden
        case quoteAssetIsNotFound
        case quoteBalanceIsNotFound
        case saleIsNotFound
        case previousOfferIsNotFound
        case failedToCancelInvestment
        
        // MARK: - LocalizedError
        
        var errorDescription: String? {
            switch self {
            case .inputIsEmpty:
                return Localized(.empty_amount)
            case .investInOwnSaleIsForbidden:
                return Localized(.investing_in_own_sale_is_forbidden)
            case .quoteBalanceIsNotFound:
                return Localized(.quote_balance_is_not_found)
            case .quoteAssetIsNotFound:
                return Localized(.quote_asset_is_not_found)
            case .saleIsNotFound:
                return Localized(.sale_is_not_found)
            case .baseBalanceIsNotFound(let asset):
                return Localized(
                    .balance_is_not_created,
                    replace: [
                        .balance_is_not_created_replace_asset: asset
                    ]
                )
            case .formatError:
                return Localized(.error_while_formatting_orderbookid)
            case .feeError(let error):
                let message = error.localizedDescription
                return Localized(
                    .fee_error,
                    replace: [
                        .fee_error_replace_message: message
                    ]
                )
            case .insufficientFunds:
                return Localized(.insufficient_funds)
                
            case .previousOfferIsNotFound:
                return Localized(.investment_to_be_cancelled_is_not_found)
                
            case .failedToCancelInvestment:
                return Localized(.failed_to_cancel_investment)
            }
        }
    }
}

extension SaleDetails.Event.CancelInvestAction.Response {
    
    typealias CancellationError = SaleDetails.Event.InvestAction.Response.InvestError
}
