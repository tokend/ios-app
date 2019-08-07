import Foundation

enum TransactionsListScene {
    
    // MARK: - Typealiases
    
    typealias Identifier = UInt64
    typealias Asset = String

    // MARK: -
    
    enum Model {}
    enum Event {}
}

extension TransactionsListScene.Model {
    struct SceneModel {
        var asset: String
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
        let type: TransactionType
        let amount: Amount
        let amountType: AmountType
        let counterparty: String?
        let rate: Amount?
        let date: Date
        
        enum TransactionType {
            case payment(sent: Bool)
            case createIssuance
            case createWithdrawal
            case manageOffer(sold: Bool)
            case checkSaleState(income: Bool)
            case pendingOffer(buy: Bool)
        }
        
        enum AmountType {
            case positive
            case negative
            case neutral
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
}
