import Foundation

enum TransactionsListScene {
    
    // MARK: - Typealiases
    
    typealias Identifier = UInt64
    typealias BalanceId = String

    // MARK: -
    
    enum Model {}
    enum Event {}
}

extension TransactionsListScene.Model {
    struct SceneModel {
        var asset: String
        var balanceId: String?
        var sections: [SectionModel]
        var sectionTitleIndex: Int?
        var sectionTitleDate: Date?
        var loadingStatus: TransactionsListScene.TransactionsFetcherProtocol.LoadingStatus
    }
    
    struct Amount {
        let value: Decimal
        let asset: String
    }
    
    struct Transaction {
        let identifier: TransactionsListScene.Identifier
        let balanceId: String
        let amount: Amount
        let amountEffect: AmountEffect
        let counterparty: String?
        let date: Date
        
        enum TransactionType {
            case payment(income: Bool)
            case createIssuance
            case createWithdrawal
            case manageOffer(income: Bool)
            case checkSaleState(income: Bool)
            case pendingOffer(income: Bool)
        }
        
        enum AmountEffect {
            // swiftlint:disable identifier_name
            case charged
            case charged_from_locked
            case funded
            case issued
            case locked
            case matched
            case no_effect
            case unlocked
            case withdrawn
            case pending
            case sale
            // swiftlint:enable identifier_name
        }
    }
    
    struct SectionModel {
        let date: Date?
        let transactions: [Transaction]
    }
    
    struct SectionViewModel {
        let title: String?
        let rows: [TransactionsListTableViewCell.Model]
    }
    
    struct ViewConfig {
        let actionButtonIsHidden: Bool
    }
    
    enum ActionType {
        case deposit(assetId: String)
        case receive
        case send(balanceId: String)
        case withdraw(balanceId: String)
    }
    
    enum ActionFilter {
        case balanceId
        case asset
    }
}

extension TransactionsListScene.Event {
    enum ViewDidLoad {
        struct Request { }
    }
    
    enum TransactionsDidUpdate {
        enum Response {
            case success(sections: [TransactionsListScene.Model.SectionModel])
            case failed(error: Swift.Error)
        }
        
        enum ViewModel {
            case empty(title: String)
            case sections([TransactionsListScene.Model.SectionViewModel])
        }
    }
    
    enum DidInitiateRefresh {
        struct Request { }
    }
    
    enum DidInitiateLoadMore {
        struct Request { }
    }
    
    enum LoadingStatusDidChange {
        typealias Response = TransactionsListScene.TransactionsFetcherProtocol.LoadingStatus
        typealias ViewModel = TransactionsListScene.TransactionsFetcherProtocol.LoadingStatus
    }
    
    enum AssetDidChange {
        struct Request {
            let asset: String
        }
    }
    
    enum BalanceDidChange {
        struct Request {
            let balanceId: String?
        }
    }
    
    enum ActionsDidChange {
        struct Response {
            let actions: [TransactionsListScene.ActionModel]
        }
        typealias ViewModel = Response
    }
    
    enum ScrollViewDidScroll {
        struct Request {
            let indexPath: IndexPath
        }
    }
    
    enum HeaderTitleDidChange {
        struct Response {
            let date: Date?
            let animated: Bool
            let animateDown: Bool
        }
        struct ViewModel {
            let title: String?
            let animation: TableViewStickyHeader.ChangeTextAnimationType
        }
    }
    
    enum SendAction {
        struct Request {}
        
        struct Response {
            let balanceId: String?
        }
        
        struct ViewModel {
            let balanceId: String?
        }
    }
}
