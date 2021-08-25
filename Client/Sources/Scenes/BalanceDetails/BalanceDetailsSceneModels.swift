import UIKit
import DifferenceKit

public enum BalanceDetailsScene {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension BalanceDetailsScene.Model {
    
    struct Section: SectionViewModel {
        
        let id: String
        let header: HeaderFooterViewAnyModel?
        let cells: [CellViewAnyModel]
    }
    
    struct SceneModel {
        
        var loadingStatus: LoadingStatus
        var transactions: [Transaction]
    }
    
    struct SceneViewModel {
        
        let isLoading: Bool
        let content: Content
        
        enum Content {
            case content(sections: [Section])
            case empty
        }
    }
    
    public enum LoadingStatus {
        case loading
        case loaded
    }
    
    public struct Transaction {
        
        enum Action {
            
            case locked
            case chargedFromLocked
            case unlocked
            case charged
            case withdrawn
            case matched
            case issued
            case funded
        }
        
        enum TransactionType {
            
            case amlAlert
            case offer
            case matchedOffer
            case investment
            case saleCancellation
            case offerCancellation
            case issuance
            case payment(counterpartyAccountId: String, counterpartyName: String?)
            case withdrawalRequest(destinationAccountId: String)
            case assetPairUpdate
            case atomicSwapAskCreation
            case atomicSwapBidCreation
        }
        
        let id: String
        let amount: Decimal
        let asset: String
        let action: Action
        let transactionType: TransactionType
    }
}

// MARK: - Events

extension BalanceDetailsScene.Event {
    
    public typealias Model = BalanceDetailsScene.Model
    
    // MARK: -
    
    public enum ViewDidLoad {
        public struct Request {}
    }

    public enum ViewDidLoadSync {
        public struct Request {}
    }
    
    public enum SceneDidUpdate {
        public struct Response {
            let sceneModel: Model.SceneModel
            let animated: Bool
        }

        public struct ViewModel {
            let viewModel: Model.SceneViewModel
            let animated: Bool
        }
    }

    public enum SceneDidUpdateSync {
        public struct Response {
            let sceneModel: Model.SceneModel
            let animated: Bool
        }

        public struct ViewModel {
            let viewModel: Model.SceneViewModel
            let animated: Bool
        }
    }
    
    public enum DidRefresh {
        public struct Request { }
    }
}

extension BalanceDetailsScene.Model.Section: DifferentiableSection {
    
    var differenceIdentifier: String {
        id
    }
    
    func isContentEqual(to source: BalanceDetailsScene.Model.Section) -> Bool {
        header.equalsTo(another: source.header)
    }
    
    init(source: BalanceDetailsScene.Model.Section,
         elements: [CellViewAnyModel]) {
        
        self.id = source.id
        self.header = source.header
        self.cells = elements
    }
}
