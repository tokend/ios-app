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
        
        public enum Period: String, Hashable, Comparable {
            case hour
            case day
            case week
            case month
            case year
            
            // MARK: - Public
            
            public var weight: Int {
                switch self {
                case .hour: return 1
                case .day: return 2
                case .week: return 3
                case .month: return 4
                case .year: return 5
                }
            }
            
            public static func < (left: Period, right: Period) -> Bool {
                return left.weight < right.weight
            }
        }
        
        public struct OrderBook {
            
            public let buyItems: [Offer]
            public let sellItems: [Offer]
            
            public var maxBuyVolume: Decimal {
                return self.buyItems.last?.volume ?? 0
            }
            
            public var maxSellVolume: Decimal {
                return self.sellItems.last?.volume ?? 0
            }
            
            public var maxVolume: Decimal {
                return max(self.maxBuyVolume, self.maxSellVolume)
            }
        }
        
        public struct Offer: Equatable {
            
            public let amount: Amount
            public let price: Amount
            public let volume: Decimal
            public let isBuy: Bool
            
            public init(
                amount: Amount,
                price: Amount,
                volume: Decimal,
                isBuy: Bool
                ) {
                
                self.amount = amount
                self.price = price
                self.volume = volume
                self.isBuy = isBuy
            }
        }
        
        public struct Trade: Equatable {
            
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
        public var selectedTab: ContentTab
        public var orderBook: OrderBook
        public var selectedPeriod: Period?
        public var charts: Charts?
        public var periods: [Period] = []
        public var trades: [Trade] = []
        
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
            let buyItems: [Offer] = []
            let sellItems: [Offer] = []
            self.orderBook = OrderBook(buyItems: buyItems, sellItems: sellItems)
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
    
    public struct Amount: Equatable {
        
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
        public let isLoading: Bool
        
        public init(
            price: String,
            amount: String,
            time: String,
            priceGrowth: Bool,
            isLoading: Bool
            ) {
            
            self.price = price
            self.amount = amount
            self.time = time
            self.priceGrowth = priceGrowth
            self.isLoading = isLoading
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
    
    public enum SwipeDirection {
        case left
        case right
    }
}

// MARK: - Events

extension TradeOffers.Event {
    public typealias Model = TradeOffers.Model
    
    // MARK: -
    
    public enum ViewDidLoad {
        
        public struct Request {
            
            public let offersPageSize: Int
            public let tradesPageSize: Int
            
            public init(
                offersPageSize: Int,
                tradesPageSize: Int
                ) {
                
                self.offersPageSize = offersPageSize
                self.tradesPageSize = tradesPageSize
            }
        }
        
        public struct Response {
            
            public let assetPair: Model.AssetPair
            public let tabs: [Model.ContentTab]
            public let selectedIndex: Int?
            public let periods: [Model.Period]
            public let selectedPeriodIndex: Int?
            
            public init(
                assetPair: Model.AssetPair,
                tabs: [Model.ContentTab],
                selectedIndex: Int?,
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
            public let selectedIndex: Int?
            public let periods: [Model.PeriodViewModel]
            public let selectedPeriodIndex: Int?
            public let axisFomatters: Model.AxisFormatters
            
            public init(
                assetPair: Model.AssetPair,
                tabs: [(title: String, tab: Model.ContentTab)],
                selectedIndex: Int?,
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
    
    public enum ChartPairPriceDidChange {
        
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
    
    public enum ChartPeriodsDidChange {
        
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
        
        public enum Response {
            
            case charts([Model.Chart])
            case error(Swift.Error)
        }
        
        public enum ViewModel {
            
            case charts([ChartDataEntry])
            case error(String)
        }
    }
    
    public enum OffersDidUpdate {
        
        public enum Response {
            case error(error: Swift.Error)
            case offers(
                buy: [Model.Offer],
                sell: [Model.Offer],
                maxVolume: Decimal
            )
        }
        
        public enum ViewModel {
            case error(error: String)
            case cells(
                buy: [OrderBookTableViewCellModel<OrderBookTableViewBuyCell>],
                sell: [OrderBookTableViewCellModel<OrderBookTableViewSellCell>]
            )
        }
    }
    
    public enum TradesDidUpdate {
        
        public enum Response {
            case error(Swift.Error)
            case trades(trades: [Model.Trade], hasMoreItems: Bool)
        }
        
        public enum ViewModel {
            case error(String)
            case trades(trades: [Model.TradeViewModel])
        }
    }
    
    public enum Loading {
        
        public struct Response {
            
            public let isLoading: Bool
            public let content: Model.ContentTab
            
            public init(
                isLoading: Bool,
                content: Model.ContentTab
                ) {
                
                self.isLoading = isLoading
                self.content = content
            }
        }
        
        public typealias ViewModel = Response
    }
    
    public enum PullToRefresh {
        
        public typealias Request = Model.ContentTab
    }
    
    public enum LoadMore {
        
        public typealias Request = Model.ContentTab
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
    
    public enum SwipeRecognized {
        public typealias Request = Model.SwipeDirection
        
        public struct Response {
            let index: Int
        }
        
        public typealias ViewModel = Response
    }
}
