import UIKit

public enum BalancePicker {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension BalancePicker.Model {
    
    struct SceneModel {
        var balances: [Balance]
        var filter: String?
    }
    
    public struct Balance {
        let assetCode: String
        let iconUrl: URL?
        let details: BalanceDetails
    }
    
    public struct BalanceDetails {
        let amount: Decimal
        let balanceId: String
    }
    
    public enum ImageRepresentation {
        case image(URL)
        case abbreviation
    }
}

// MARK: - Events

extension BalancePicker.Event {
    public typealias Model = BalancePicker.Model
    
    // MARK: -
    
    public enum ViewDidLoad {
        public struct Request {}
    }
    
    public enum BalancesUpdated {
        public enum Response {
            case balances([Model.Balance])
            case empty
        }
        
        public enum ViewModel {
            case balances([BalancePicker.BalanceCell.ViewModel])
            case empty
        }
    }
    
    public enum DidFilter {
        public struct Request {
            let filter: String?
        }
    }
}
