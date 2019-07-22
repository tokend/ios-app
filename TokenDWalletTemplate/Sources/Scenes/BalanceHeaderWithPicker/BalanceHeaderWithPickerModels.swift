import Foundation

enum BalanceHeaderWithPicker {
    
    // MARK: - Typealiases
    
    typealias Identifier = String
    
    // MARK: -
    
    enum Model {}
    enum Event {}
}

// MARK: - Models

extension BalanceHeaderWithPicker.Model {
    struct SceneModel {
        var balances: [Balance]
        var selectedBalanceId: BalanceHeaderWithPicker.Identifier?
    }
    
    struct Balance {
        let balance: Amount
        let balanceId: BalanceHeaderWithPicker.Identifier?
    }
    
    struct BalanceViewModel {
        let id: BalanceHeaderWithPicker.Identifier?
        let name: String
        let asset: String
    }
    
    struct Amount {
        let value: Decimal
        let asset: String
    }
}

// MARK: - Events

extension BalanceHeaderWithPicker.Event {
    typealias Model = BalanceHeaderWithPicker.Model
    
    enum DidInjectModules {
        struct Request { }
    }
    
    enum BalancesDidChange {
        struct Response {
            let balances: [Model.Balance]
            let selectedBalanceId: BalanceHeaderWithPicker.Identifier?
            var selectedBalanceIndex: Int?
        }
        
        struct ViewModel {
            let balances: [Model.BalanceViewModel]
            let selectedBalanceId: BalanceHeaderWithPicker.Identifier?
            var selectedBalanceIndex: Int?
        }
    }
    
    enum SelectedBalanceDidChange {
        struct Request {
            let id: BalanceHeaderWithPicker.Identifier
        }
        
        struct Response {
            let balance: Model.Amount
            let rate: Model.Amount?
            let id: BalanceHeaderWithPicker.Identifier?
            let asset: String
        }
        
        struct ViewModel {
            let balance: String
            let rate: String?
            let id: BalanceHeaderWithPicker.Identifier?
            let asset: String
        }
    }
}

extension BalanceHeaderWithPicker.Model.Balance: Hashable {
    typealias SelfType = BalanceHeaderWithPicker.Model.Balance
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.balanceId?.hashValue ?? balance.asset.hashValue)
    }
    
    static func == (lhs: SelfType, rhs: SelfType) -> Bool {
        if let left = lhs.balanceId,
            let right = rhs.balanceId {
            return left == right
        } else if lhs.balanceId == nil,
            rhs.balanceId == nil {
            return false
        } else {
            return lhs.balance.asset == rhs.balance.asset
        }
    }
}
