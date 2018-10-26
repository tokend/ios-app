import Foundation
import UIKit

enum TransactionDetails {
    
    // MARK: - Typealiases
    
    typealias CellIdentifier = String
    
    // MARK: -
    
    enum Model {}
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
    
    struct SectionModel {
        let title: String
        let cells: [CellModel]
        let description: String
    }
    
    struct CellModel {
        let title: String
        let value: String
        let identifier: TransactionDetails.CellIdentifier
    }
    
    struct SectionViewModel {
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
                let title: String
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
}
