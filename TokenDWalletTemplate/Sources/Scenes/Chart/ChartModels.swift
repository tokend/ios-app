import UIKit

public enum Chart {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension Chart.Model {
    
    public struct SceneModel {
        var sale: SaleModel?
        var charts: [Period: [ChartEntry]]
        var chartsPeriods: [Period]
        var selectedChartsPeriod: Period?
        var selectedChartEntryIndex: Int?
        
        init() {
            
            self.sale = nil
            self.charts = [:]
            self.chartsPeriods = []
            self.selectedChartsPeriod = nil
            self.selectedChartEntryIndex = nil
        }
    }
    
    public struct ChartModel {
        let asset: String
        
        let investedAmount: Decimal
        let investedDate: Date?
        
        let datePickerItems: [Period]
        let selectedDatePickerItem: Int?
        
        let growth: Decimal
        let growthPositive: Bool?
        let growthSincePeriod: Period?
        
        let chartInfoModel: ChartInfoModel
    }
    
    public struct ChartViewModel {
        let title: String
        let subTitle: String
        
        let datePickerItems: [PeriodViewModel]
        let selectedDatePickerItemIndex: Int
        
        let growth: String
        let growthPositive: Bool?
        let growthSinceDate: String
        
        let axisFormatters: AxisFormatters
        let chartInfoViewModel: ChartInfoViewModel
    }
    
    public struct ChartUpdatedViewModel {
        let selectedPeriodIndex: Int
        
        let growth: String
        let growthPositive: Bool?
        let growthSinceDate: String
        
        let axisFormatters: AxisFormatters
        let chartInfoViewModel: ChartInfoViewModel
    }
    
    struct ChartEntrySelectedViewModel {
        let title: String
        let subTitle: String
    }
    
    public enum Period: Int, Hashable, Equatable {
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
    
    public struct PeriodViewModel {
        let title: String
        let isEnabled: Bool
        let period: Period
    }
    
    public struct ChartInfoModel {
        let entries: [ChartEntry]
        let limits: [LimitLineModel]
    }
    
    public struct LimitLineModel {
        let value: Decimal
        let type: LimitLineType
    }
    
    public struct ChartEntry {
        let date: Date
        let value: Decimal
    }
    
    public struct ChartInfoViewModel {
        let entries: [ChartDataEntry]
        let limits: [LimitLineViewModel]
    }
    
    public struct ChartDataEntry {
        let x: Double
        let y: Double
    }
    
    public struct LimitLineViewModel {
        let value: Double
        let label: String
        let type: LimitLineType
    }
    
    public struct AxisFormatters {
        let xAxisFormatter: (Double) -> String
        let yAxisFormatter: (Double) -> String
    }
    
    struct SaleModel {
        let baseAsset: String
        let quoteAsset: String
        let softCap: Decimal
        let hardCap: Decimal
    }
    
    public enum LimitLineType {
        case current
        case hardCap
        case softCap
    }
    
    public enum Error: Swift.Error {
        case empty
        case other(Swift.Error)
    }
    
    public enum ErrorStatus: String {
        case notFound = "404"
    }
}

// MARK: - Events

extension Chart.Event {
    public typealias Model = Chart.Model
    
    // MARK: -
    
    public enum ViewDidLoad {
        public struct Request {}
    }
    
    public enum ChartDidUpdate {
        public enum Response {
            case chart(Model.ChartModel)
            case error(Swift.Error)
        }
        
        public enum ViewModel {
            case chart(Model.ChartViewModel)
            case error(Chart.EmptyContent.ViewModel)
        }
    }
    
    public enum SelectChartPeriod {
        public struct Request {
            let period: Int
        }
        
        public struct Response {
            let asset: String
            
            let periods: [Model.Period]
            let selectedPeriod: Model.Period
            let selectedPeriodIndex: Int?
            
            let growth: Decimal
            let growthPositive: Bool?
            let growthSincePeriod: Model.Period?
            
            let chartInfoModel: Model.ChartInfoModel
            
            let updatedModel: Model.ChartModel
        }
        
        public struct ViewModel {
            let viewModel: Model.ChartUpdatedViewModel
            let updatedViewModel: Model.ChartViewModel
        }
    }
    
    public enum SelectChartEntry {
        public struct Request {
            let chartEntryIndex: Int?
        }
        
        public struct Response {
            let asset: String
            let investedAmount: Decimal
            let investedDate: Date?
        }
        
        public struct ViewModel {
            let viewModel: Model.ChartEntrySelectedViewModel
        }
    }
    
    public enum DidSelectChartItem {
        public struct Request {
            let itemIndex: Int?
        }
    }
    
    public enum DidSelectPickerItem {
        public struct Request {
            let index: Int?
        }
    }
}
