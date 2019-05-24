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
    
    public struct SectionModel {
        let cells: [CellModel]
    }
    
    public struct SectionViewModel {
        let cells: [CellViewModel]
    }

    public enum CellModel {
        case header(Header)
        case balance(Balance)
    }
    
    public enum CellViewModel {
        case header(BalancesList.HeaderCell.ViewModel)
        case balance(BalancesList.BalanceCell.ViewModel)
    }
    
    public struct Header {
        let balance: Decimal
        let asset: String
    }
    
    public struct Balance {
        let code: String
        let balance: Decimal
        let balanceId: String
        let convertedBalance: Decimal
    }
}

// MARK: - Events

extension BalancesList.Event {
    public typealias Model = BalancesList.Model
    
    // MARK: -
    
    public enum ViewDidLoad {
        public struct Request {}
    }
    
    public enum CellsWasUpdated {
        public struct Response {
            let sections: [Model.SectionModel]
        }
        
        public struct ViewModel {
            let sections: [Model.SectionViewModel]
        }
    }
}
