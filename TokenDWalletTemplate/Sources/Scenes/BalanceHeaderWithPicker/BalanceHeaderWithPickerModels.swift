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
    
    struct Amount {
        let value: Decimal
        let asset: String
    }
}

// MARK: - Events

extension BalanceHeaderWithPicker.Event {
    typealias Model = BalanceHeaderWithPicker.Model
    
    enum BalanceDidChange {
        struct Response {
            let balance: Model.Amount
            let rate: Model.Amount?
        }
        
        struct ViewModel {
            let balance: String
            let rate: String?
        }
    }
    
    enum SelectedBalanceDidChange {
        struct Model {
            let index: Int
        }
        
        typealias Response = Model
        typealias ViewModel = Model
    }
    
    enum RateDidChange {
        struct Response {
            let rate: Model.Amount?
        }
        
        struct ViewModel {
            let rate: String?
        }
    }
    
    enum BalancesDidChange {
        struct Response {
            let balances: [Model.Balance]
        }
        
        struct ViewModel {
            let balances: [Balance]
        }
    }
    
    enum DidSelectBalance {
        struct Request {
            let id: BalanceHeaderWithPicker.Identifier
        }
    }
    
    enum DidInjectModules {
        struct Request { }
    }
}

extension BalanceHeaderWithPicker.Event.BalancesDidChange.ViewModel {
    struct Balance {
        let id: BalanceHeaderWithPicker.Identifier?
        let name: String
        let asset: String
    }
}

extension BalanceHeaderWithPicker.Model.Balance: Hashable {
    typealias SelfType = BalanceHeaderWithPicker.Model.Balance
    
    var hashValue: Int {
        return self.balanceId?.hashValue ?? balance.asset.hashValue
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
