import Foundation
import UIKit

public enum TransactionDetails {
    
    // MARK: - Typealiases
    
    // MARK: -
    
    public enum CellIdentifier: String {
        case date
        case description
        case recipient
        case amount
        case fee
        case feePecipient
        case fromAccount
        case subject
        case state
        case destination
        case paid
        case amountSent
        case fixedFee
        case percentFee
        case sent
        case warning
        case received
        case price
        case invest
        case toAccount
        case toPay
        case toPayAmount
        case toPayFee
        case toReceive
        case toReceivePrice
        case lowerBound
        case upperBound
        case subtype
        case fixed
        case percent
        case lowercased
        case startTime
        case closeTime
        case baseAsset
        case softCap
        case hardCap
        case available
        case issued
        case max
        case effect
        case reference
        case total
        case code
        case tradable
        case physicalPrice
        case currentPrice
        case charged
        case matched
        case locked
        case unlocked
        case token
        case sender
        case unknown
        case check
        case email
    }
    
    public enum Model {}
    enum Event {}
}

// MARK: - Models

extension TransactionDetails.Model {
    
    struct Amount {
        let value: Decimal
        let asset: String
    }
    
    class SceneModel {
        var sections: [SectionModel] = []
    }
    
    public struct SectionModel {
        public let title: String
        public let cells: [CellModel]
        public let description: String
    }
    
    public struct CellModel: Equatable {
        let title: String
        let hint: String
        let identifier: TransactionDetails.CellIdentifier
        var isSeparatorHidden: Bool
        
        init(
            title: String,
            hint: String,
            identifier: TransactionDetails.CellIdentifier,
            isSeparatorHidden: Bool = false
            ) {
            
            self.title = title
            self.hint = hint
            self.identifier = identifier
            self.isSeparatorHidden = isSeparatorHidden
        }
    }
    
    public struct SectionViewModel {
        let title: String?
        let cells: [CellViewAnyModel]
        let description: String?
    }
    
    struct Transaction {
        let title: String
        let value: String
    }
}

// MARK: - Events

extension TransactionDetails.Event {
    enum ViewDidLoad {
        struct Request {}
        struct Response {}
        struct ViewModel {}
    }
    
    enum TransactionUpdated {
        enum Response {
            case loading
            case loaded
            case succeeded([TransactionDetails.Model.SectionModel])
        }
        enum ViewModel {
            case loading
            case loaded
            case succeeded([TransactionDetails.Model.SectionViewModel])
        }
    }
    
    enum TransactionActionsDidUpdate {
        struct Action {
            struct Item {
                let id: String
                let icon: UIImage
                let title: String
                let message: String
            }
            
            let rightItems: [Item]
        }
        typealias Response = Action
        typealias ViewModel = Action
    }
    
    enum TransactionAction {
        struct Request {
            let id: String
        }
        enum Action {
            case success
            case loading
            case loaded
            case error(String)
        }
        typealias Response = Action
        typealias ViewModel = Action
    }
    
    enum SelectedCell {
        struct Request {
            let model: CellViewAnyModel
        }
        struct Response {
            let message: String
        }
        typealias ViewModel = Response
    }
}
