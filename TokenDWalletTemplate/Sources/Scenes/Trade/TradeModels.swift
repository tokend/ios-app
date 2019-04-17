import Foundation
import Charts

public enum Trade {
    
    // MARK: - Typealiases
    
    typealias PairID = String
    typealias Charts = [Model.Period: [Model.Chart]]
    
    // MARK: - Models
    
    public struct Model {}
    struct Event {}
}

extension Trade.Model {
    public struct Asset {
        let baseAsset: String
        let quoteAsset: String
        let currentPrice: Decimal
    }
    
    enum Period: String, Hashable {
        case hour
        case day
        case week
        case month
        case year
    }
    
    struct Chart {
        let date: Date
        let value: Decimal
    }
    
    struct SceneModel {
        var pairs: [Asset]
        var selectedPair: Asset?
        var selectedPeriod: Period?
        var charts: Trade.Charts?
        var buyOffers: [Offer]?
        var sellOffers: [Offer]?
        var periods: [Period] = []
    }
    
    struct Offer {
        let amount: Amount
        let price: Amount
        let isBuy: Bool
    }
    
    struct Pair {
        let base: String
        let quote: String
        
        let id: Trade.PairID
    }
    
    struct PairViewModel {
        let title: String
        let id: Trade.PairID
    }
    
    struct Amount {
        let value: Decimal
        let currency: String
    }
    
    struct PeriodViewModel {
        let title: String
        let isEnabled: Bool
        let period: Period?
    }
    
    struct AxisFormatters {
        let xAxisFormatter: (Double) -> String
        let yAxisFormatter: (Double) -> String
    }
}

extension Trade.Event {
    enum ViewDidLoadSync {
        struct Request {}
        struct Response {
            let pairs: [Trade.Model.Pair]
            let selectedPairIndex: Int?
            let selectedPeriodIndex: Int?
            let base: String?
            let quote: String?
            let periods: [Trade.Model.Period]
        }
        struct ViewModel {
            let pairs: [Trade.Model.PairViewModel]
            let selectedPairIndex: Int?
            let selectedPeriodIndex: Int?
            let base: String?
            let quote: String?
            let periods: [Trade.Model.PeriodViewModel]
            let axisFomatters: Trade.Model.AxisFormatters
        }
    }
    
    enum ViewWillAppear {
        struct Request {}
    }
    
    enum PairsDidChange {
        struct Response {
            let pairs: [Trade.Model.Pair]
            let selectedPairIndex: Int?
        }
        struct ViewModel {
            let pairs: [Trade.Model.PairViewModel]
            let selectedPairIndex: Int?
        }
    }
    
    enum DidHighlightChart {
        struct Request {
            let index: Int?
        }
    }
    
    enum PairPriceDidChange {
        struct Response {
            let price: Trade.Model.Amount?
            let per: Trade.Model.Amount?
            let timestamp: Date?
        }
        struct ViewModel {
            let price: String?
            let per: String?
        }
    }
    
    enum DidSelectPair {
        struct Request {
            let pairID: Trade.PairID
        }
        struct Response {
            let base: String?
            let quote: String?
        }
        struct ViewModel {
            let base: String?
            let quote: String?
        }
    }
    
    enum DidSelectPeriod {
        struct Request {
            let period: Trade.Model.Period
        }
    }
    
    enum PeriodsDidChange {
        struct Response {
            let periods: [Trade.Model.Period]
            let selectedPeriodIndex: Int?
        }
        struct ViewModel {
            let periods: [Trade.Model.PeriodViewModel]
            let selectedPeriodIndex: Int?
        }
    }
    
    enum ChartDidUpdate {
        struct Response {
            let charts: [Trade.Model.Chart]?
        }
        struct ViewModel {
            let chartEntries: [ChartDataEntry]?
        }
    }
    
    enum SellOffersDidUpdate {
        struct Response {
            let offers: [Trade.Model.Offer]?
        }
        enum ViewModel {
            case empty
            case cells([OrderBookTableViewCellModel<OrderBookTableViewSellCell>])
        }
    }
    
    enum BuyOffersDidUpdate {
        struct Response {
            let offers: [Trade.Model.Offer]?
        }
        enum ViewModel {
            case empty
            case cells([OrderBookTableViewCellModel<OrderBookTableViewBuyCell>])
        }
    }
    
    enum Loading {
        struct Model {
            let showForChart: Bool? // nil if should not change current state
            let showForBuyTable: Bool? // nil if should not change current state
            let showForSellTable: Bool? // nil if should not change current state
            let showForAssets: Bool? // nil if should not change current state
        }
        typealias Response = Model
        typealias ViewModel = Model
    }
    
    enum CreateOffer {
        struct Request {
            let amount: Trade.Model.Amount?
            let price: Trade.Model.Amount?
        }
        struct Model {
            let amount: Trade.Model.Amount?
            let price: Trade.Model.Amount?
            let baseAsset: String
            let quoteAsset: String
        }
        typealias Response = Model
        typealias ViewModel = Model
    }
    
    enum ChartFormatterDidChange {
        struct Response {
            let period: Trade.Model.Period
        }
        struct ViewModel {
            let axisFormatters: Trade.Model.AxisFormatters
        }
    }
    
    enum Error {
        struct Response {
            let error: Swift.Error
        }
        struct ViewModel {
            let message: String
        }
    }
}
