import UIKit
import Charts

public enum TradeOffers {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {
        
        public enum ContentTab {
            case orderBook
            case chart
            case trades
        }
        
        public enum Period: String, Hashable {
            case hour
            case day
            case week
            case month
            case year
        }
        
        public struct Offer {
            
            public let amount: Amount
            public let price: Amount
            public let isBuy: Bool
            
            public init(
                amount: Amount,
                price: Amount,
                isBuy: Bool
                ) {
                
                self.amount = amount
                self.price = price
                self.isBuy = isBuy
            }
        }
        
        public struct Trade {
            
            public let amount: Decimal
            public let price: Decimal
            public let date: Date
            public let priceGrows: Bool
            
            public init(
                amount: Decimal,
                price: Decimal,
                date: Date,
                priceGrows: Bool
                ) {
                
                self.amount = amount
                self.price = price
                self.date = date
                self.priceGrows = priceGrows
            }
        }
    }
    public enum Event {}
}

// MARK: - Models

extension TradeOffers.Model {
    
    public typealias Asset = String
    public typealias Charts = [Period: [Chart]]
    public typealias PairID = String
    
    public struct SceneModel {
        
        public let assetPair: AssetPair
        public let tabs: [ContentTab]
        public var buyOffers: [Offer]?
        public var charts: Charts?
        public var periods: [Period] = []
        public var selectedPeriod: Period?
        public var selectedTab: ContentTab
        public var sellOffers: [Offer]?
        public var trades: [Trade]?
        
        public init(
            assetPair: AssetPair,
            selectedTab: ContentTab = .orderBook,
            selectedPeriod: Period = .day
            ) {
            
            self.assetPair = assetPair
            self.selectedTab = selectedTab
            self.selectedPeriod = selectedPeriod
            self.tabs = [
                .orderBook,
                .chart,
                .trades
            ]
        }
    }
    
    public struct AssetPair {
        
        public let baseAsset: Asset
        public let quoteAsset: Asset
        public let currentPrice: Decimal
        
        public init(
            baseAsset: Asset,
            quoteAsset: Asset,
            currentPrice: Decimal
            ) {
            
            self.baseAsset = baseAsset
            self.quoteAsset = quoteAsset
            self.currentPrice = currentPrice
        }
    }
    
    public struct Chart {
        
        public let date: Date
        public let value: Decimal
        
        public init(
            date: Date,
            value: Decimal
            ) {
            
            self.date = date
            self.value = value
        }
    }
    
    public struct Amount {
        
        public let value: Decimal
        public let currency: String
        
        public init(
            value: Decimal,
            currency: String
            ) {
            
            self.value = value
            self.currency = currency
        }
    }
    
    public struct PeriodViewModel {
        
        public let title: String
        public let isEnabled: Bool
        public let period: Period?
        
        public init(
            title: String,
            isEnabled: Bool,
            period: Period?
            ) {
            
            self.title = title
            self.isEnabled = isEnabled
            self.period = period
        }
    }
    
    public struct TradeViewModel {
        
        public let price: String
        public let amount: String
        public let time: String
        public let priceGrowth: Bool
        
        public init(
            price: String,
            amount: String,
            time: String,
            priceGrowth: Bool
            ) {
            
            self.price = price
            self.amount = amount
            self.time = time
            self.priceGrowth = priceGrowth
        }
    }
    
    public struct AxisFormatters {
        
        public let xAxisFormatter: (Double) -> String
        public let yAxisFormatter: (Double) -> String
        
        public init(
            xAxisFormatter: @escaping (Double) -> String,
            yAxisFormatter: @escaping (Double) -> String
            ) {
            
            self.xAxisFormatter = xAxisFormatter
            self.yAxisFormatter = yAxisFormatter
        }
    }
}

// MARK: - Events

extension TradeOffers.Event {
    public typealias Model = TradeOffers.Model
    
    // MARK: -
    
    public enum ViewDidLoad {
        
        public struct Request { public init() {} }
        
        public struct Response {
            
            public let assetPair: Model.AssetPair
            public let tabs: [Model.ContentTab]
            public let selectedIndex: Int
            public let periods: [Model.Period]
            public let selectedPeriodIndex: Int?
            
            public init(
                assetPair: Model.AssetPair,
                tabs: [Model.ContentTab],
                selectedIndex: Int,
                periods: [Model.Period],
                selectedPeriodIndex: Int?
                ) {
                
                self.assetPair = assetPair
                self.tabs = tabs
                self.selectedIndex = selectedIndex
                self.periods = periods
                self.selectedPeriodIndex = selectedPeriodIndex
            }
        }
        
        public struct ViewModel {
            
            public let assetPair: Model.AssetPair
            public let tabs: [(title: String, tab: Model.ContentTab)]
            public let selectedIndex: Int
            public let periods: [Model.PeriodViewModel]
            public let selectedPeriodIndex: Int?
            public let axisFomatters: Model.AxisFormatters
            
            public init(
                assetPair: Model.AssetPair,
                tabs: [(title: String, tab: Model.ContentTab)],
                selectedIndex: Int,
                periods: [Model.PeriodViewModel],
                selectedPeriodIndex: Int?,
                axisFomatters: Model.AxisFormatters
                ) {
                
                self.assetPair = assetPair
                self.tabs = tabs
                self.selectedIndex = selectedIndex
                self.periods = periods
                self.selectedPeriodIndex = selectedPeriodIndex
                self.axisFomatters = axisFomatters
            }
        }
    }
    
    public enum ViewWillAppear {
        
        public struct Request { public init() {} }
    }
    
    public enum ScreenTitleUpdated {
        
        public struct Response {
            
            public let baseAsset: Model.Asset
            public let quoteAsset: Model.Asset
            public let currentPrice: Decimal
            
            public init(
                baseAsset: Model.Asset,
                quoteAsset: Model.Asset,
                currentPrice: Decimal
                ) {
                
                self.baseAsset = baseAsset
                self.quoteAsset = quoteAsset
                self.currentPrice = currentPrice
            }
        }
        
        public struct ViewModel {
            
            public let screenTitle: String
            public let screenSubTitle: String
            
            public init(
                screenTitle: String,
                screenSubTitle: String
                ) {
                
                self.screenTitle = screenTitle
                self.screenSubTitle = screenSubTitle
            }
        }
    }
    
    public enum ContentTabSelected {
        
        public struct Request {
            
            public let selectedTab: Model.ContentTab
            
            public init(selectedTab: Model.ContentTab) {
                self.selectedTab = selectedTab
            }
        }
        
        public typealias Response = Request
        public typealias ViewModel = Response
    }
    
    public enum DidHighlightChart {
        
        public struct Request {
            
            public let index: Int?
            
            public init(index: Int?) {
                self.index = index
            }
        }
    }
    
    public enum PairPriceDidChange {
        
        public struct Response {
            
            public let price: Model.Amount?
            public let per: Model.Amount?
            public let timestamp: Date?
            
            public init(
                price: Model.Amount?,
                per: Model.Amount?,
                timestamp: Date?
                ) {
                
                self.price = price
                self.per = per
                self.timestamp = timestamp
            }
        }
        
        public struct ViewModel {
            
            public let price: String?
            public let per: String?
            
            public init(
                price: String?,
                per: String?
                ) {
                
                self.price = price
                self.per = per
            }
        }
    }
    
    public enum DidSelectPeriod {
        
        public struct Request {
            
            public let period: Model.Period
            
            public init(period: Model.Period) {
                self.period = period
            }
        }
    }
    
    public enum PeriodsDidChange {
        
        public struct Response {
            
            public let periods: [Model.Period]
            public let selectedPeriodIndex: Int?
            
            public init(
                periods: [Model.Period],
                selectedPeriodIndex: Int?
                ) {
                
                self.periods = periods
                self.selectedPeriodIndex = selectedPeriodIndex
            }
        }
        
        public struct ViewModel {
            
            public let periods: [Model.PeriodViewModel]
            public let selectedPeriodIndex: Int?
            
            public init(
                periods: [Model.PeriodViewModel],
                selectedPeriodIndex: Int?
                ) {
                
                self.periods = periods
                self.selectedPeriodIndex = selectedPeriodIndex
            }
        }
    }
    
    public enum ChartDidUpdate {
        
        public struct Response {
            
            public let charts: [Model.Chart]?
            
            public init(charts: [Model.Chart]?) {
                self.charts = charts
            }
        }
        
        public struct ViewModel {
            
            public let chartEntries: [ChartDataEntry]?
            
            public init(chartEntries: [ChartDataEntry]?) {
                self.chartEntries = chartEntries
            }
        }
    }
    
    public enum SellOffersDidUpdate {
        
        public struct Response {
            
            public let offers: [Model.Offer]?
            
            public init(offers: [Model.Offer]?) {
                self.offers = offers
            }
        }
        
        public enum ViewModel {
            case empty
            case cells([OrderBookTableViewCellModel<OrderBookTableViewSellCell>])
        }
    }
    
    public enum BuyOffersDidUpdate {
        
        public struct Response {
            
            public let offers: [Model.Offer]?
            
            public init(offers: [Model.Offer]?) {
                self.offers = offers
            }
        }
        
        public enum ViewModel {
            case empty
            case cells([OrderBookTableViewCellModel<OrderBookTableViewBuyCell>])
        }
    }
    
    public enum TradesDidUpdate {
        
        public enum Response {
            case error(Swift.Error)
            case trades([Model.Trade])
        }
        
        public enum ViewModel {
            case error(String)
            case trades([Model.TradeViewModel])
        }
    }
    
    public enum Loading {
        
        public struct Model {
            
            // nil if should not change current state
            public let showForChart: Bool?
            public let showForBuyTable: Bool?
            public let showForSellTable: Bool?
            public let showForTrades: Bool?
            
            public init(
                showForChart: Bool?,
                showForBuyTable: Bool?,
                showForSellTable: Bool?,
                showForTrades: Bool?
                ) {
                
                self.showForChart = showForChart
                self.showForBuyTable = showForBuyTable
                self.showForSellTable = showForSellTable
                self.showForTrades = showForTrades
            }
        }
        
        public typealias Response = Model
        public typealias ViewModel = Model
    }
    
    public enum CreateOffer {
        
        public struct Request {
            
            public let amount: Model.Amount?
            public let price: Model.Amount?
            
            public init(
                amount: Model.Amount?,
                price: Model.Amount?
                ) {
                
                self.amount = amount
                self.price = price
            }
        }
        
        public struct Response {
            
            public let amount: Model.Amount?
            public let price: Model.Amount?
            public let baseAsset: String
            public let quoteAsset: String
            
            public init(
                amount: Model.Amount?,
                price: Model.Amount?,
                baseAsset: String,
                quoteAsset: String
                ) {
                
                self.amount = amount
                self.price = price
                self.baseAsset = baseAsset
                self.quoteAsset = quoteAsset
            }
        }
        
        public typealias ViewModel = Response
    }
    
    public enum ChartFormatterDidChange {
        
        public struct Response {
            
            public let period: Model.Period
            
            public init(period: Model.Period) {
                self.period = period
            }
        }
        
        public struct ViewModel {
            public let axisFormatters: Model.AxisFormatters
            
            public init(axisFormatters: Model.AxisFormatters) {
                self.axisFormatters = axisFormatters
            }
        }
    }
    
    public enum Error {
        
        public struct Response {
            
            public let error: Swift.Error
            
            public init(error: Swift.Error) {
                self.error = error
            }
        }
        
        public struct ViewModel {
            
            public let message: String
            
            public init(message: String) {
                self.message = message
            }
        }
    }
}
