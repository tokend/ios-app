import UIKit

public enum BalancesList {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension BalancesList.Model {
    
    public struct SceneModel {
        var balances: [Balance]
        var chartBalances: [ChartBalance]
        var selectedChartBalance: ChartBalance?
        let convertedAsset: String
    }
    
    public struct SectionModel {
        var cells: [CellModel]
    }
    
    public struct SectionViewModel {
        var cells: [CellViewAnyModel]
    }

    public enum CellModel {
        case header(Header)
        case balance(Balance)
        case chart(PieChartModel)
    }
    
    public struct LegendCellModel: Equatable {
        let assetName: String
        let balance: Decimal
        let isSelected: Bool
        let balancePercentage: Double
        let balanceType: ChartBalanceType
    }
    
    public struct Header {
        let balance: Decimal
        let asset: String
        let cellIdentifier: CellIdentifier
    }
    
    public struct Balance: Equatable {
        let code: String
        let assetName: String
        let iconUrl: URL?
        let balance: Decimal
        let balanceId: String
        let convertedBalance: Decimal
        let cellIdentifier: CellIdentifier
    }
    
    public struct ChartBalance: Equatable {
        let assetName: String
        let balanceId: String
        let convertedBalance: Decimal
        let balancePercentage: Double
        let type: ChartBalanceType
        
        public static func == (lhs: ChartBalance, rhs: ChartBalance) -> Bool {
            return lhs.balanceId == rhs.balanceId
        }
    }
    
    public enum ChartBalanceType {
        case balance
        case other
    }
    
    public struct PieChartEntry {
        let value: Double
    }
    
    public struct PieChartModel {
        let entries: [PieChartEntry]
        let legendCells: [LegendCellModel]
        let highlitedEntry: HighlightedEntryModel?
        let convertAsset: String
    }
    
    public struct PieChartViewModel {
        let entries: [PieChartEntry]
        let highlitedEntry: HighlightedEntryViewModel?
        let colorsPallete: [UIColor]
    }
    
    public struct HighlightedEntryModel {
        let index: Int
        let value: Double
    }
    
    public struct HighlightedEntryViewModel {
        let index: Double
        let value: NSAttributedString
    }
    
    public enum LoadingStatus {
        case loaded
        case loading
    }
    
    public enum ImageRepresentation {
        case image(URL)
        case abbreviation
    }
    
    public enum CellIdentifier {
        case balances
        case chart
        case header
    }
}

// MARK: - Events

extension BalancesList.Event {
    public typealias Model = BalancesList.Model
    
    // MARK: -
    
    public enum ViewDidLoad {
        public struct Request {}
    }
    
    public enum SectionsUpdated {
        public struct Response {
            let sections: [Model.SectionModel]
        }
        
        public struct ViewModel {
            let sections: [Model.SectionViewModel]
        }
    }
    
    public enum LoadingStatusDidChange {
        public typealias Response = Model.LoadingStatus
        public typealias ViewModel = Response
    }
    
    public enum PieChartEntriesChanged {
        public struct Response {
            let model: Model.PieChartModel
        }
        
        public struct ViewModel {
            let model: Model.PieChartViewModel
        }
    }
    
    public enum PieChartBalanceSelected {
        public struct Request {
            let value: Double
        }
        
        public struct Response {
            let pieChartModel: Model.PieChartModel
            let legendCells: [Model.LegendCellModel]
        }
        
        public struct ViewModel {
            let pieChartViewModel: Model.PieChartViewModel
            let legendCells: [BalancesList.LegendCell.ViewModel]
        }
    }
}
