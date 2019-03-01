import Foundation

enum DashboardPaymentsPlugIn {
    
    // MARK: - Typealiases
    
    typealias BalanceId = String
    
    // MARK: -
    
    enum Model {}
    enum Event {}
}

// MARK: - Models

extension DashboardPaymentsPlugIn.Model {
    struct SceneModel {
        var balances: [Balance]
        var selectedBalanceId: DashboardPaymentsPlugIn.BalanceId?
    }
    
    struct Balance {
        let balance: Amount
        let balanceId: DashboardPaymentsPlugIn.BalanceId?
    }
    
    struct BalanceViewModel {
        let id: DashboardPaymentsPlugIn.BalanceId?
        let name: String
        let asset: String
    }
    
    enum LoadingStatus {
        case loading
        case loaded
    }
    
    struct Amount {
        let value: Decimal
        let asset: String
    }
}

// MARK: - Events

extension DashboardPaymentsPlugIn.Event {
    typealias Model = DashboardPaymentsPlugIn.Model
    
    // MARK: -
    
    enum ViewDidLoadSync {
        struct Request {}
    }
    
    enum DidInitiateRefresh {
        struct Request {}
    }
    
    enum BalancesDidChange {
        struct Response {
            let balances: [Model.Balance]
            let selectedBalanceId: DashboardPaymentsPlugIn.BalanceId?
            var selectedBalanceIndex: Int?
        }
        
        struct ViewModel {
            let balances: [Model.BalanceViewModel]
            let selectedBalanceId: DashboardPaymentsPlugIn.BalanceId?
            var selectedBalanceIndex: Int?
        }
    }
    
    enum SelectedBalanceDidChange {
        struct Request {
            let id: DashboardPaymentsPlugIn.BalanceId?
        }
        
        struct Response {
            let balance: Model.Amount
            let rate: Model.Amount?
            let id: DashboardPaymentsPlugIn.BalanceId?
            let asset: String
        }
        
        struct ViewModel {
            let balance: String
            let rate: String?
            let id: DashboardPaymentsPlugIn.BalanceId?
            let asset: String
        }
    }
    
    enum DidSelectViewMore {
        struct Request { }
        struct Response {
            let balanceId: String
        }
        struct ViewModel {
            let balanceId: String
        }
    }
    
    enum ViewMoreAvailabilityChanged {
        struct Response {
            let available: Bool
        }
        struct ViewModel {
            let enabled: Bool
        }
    }
}

extension DashboardPaymentsPlugIn.Model.Balance: Hashable {
    typealias SelfType = DashboardPaymentsPlugIn.Model.Balance
    
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
