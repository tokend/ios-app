import UIKit

enum TokenDetailsScene {
    
    // MARK: - Typealiases
    
    typealias TokenIdentifier = String
    
    // MARK: -
    
    enum Model {}
    enum Event {}
}

extension TokenDetailsScene.Model {
    struct Token {
        let identifier: TokenDetailsScene.TokenIdentifier
        
        let iconUrl: URL?
        let code: String
        let name: String?
        
        let balanceState: BalanceState
        
        let availableForIssuance: Decimal
        let issued: Decimal
        let maximumIssuanceAmount: Decimal
        let policies: [String]
        
        let termsOfUse: Document?
    }
    
    struct SceneModel {
        var token: Token?
    }
    
    struct TableSection {
        let title: String?
        let cells: [CellViewAnyModel]
        let description: String?
    }
}

extension TokenDetailsScene.Event {
    enum ViewDidLoad {
        struct Request { }
    }
    
    enum TokenDidUpdate {
        struct Response {
            let token: TokenDetailsScene.Model.Token?
        }
        enum ViewModel {
            case sections([TokenDetailsScene.Model.TableSection])
            case empty
        }
    }
    
    enum DidSelectAction {
        enum Action {
            case viewHistory(balanceId: String)
        }
        
        struct Request { }
        typealias Response = Action
        typealias ViewModel = Action
    }
}

extension TokenDetailsScene.Model.Token {
    enum IconState {
        case loading
        case icon(UIImage)
        case noIcon
    }
}

extension TokenDetailsScene.Model.Token {
    enum BalanceState {
        case creating
        case created(balanceId: String)
        case notCreated
    }
}

extension TokenDetailsScene.Model.Token {
    struct Document {
        let name: String
        let link: URL
    }
}

extension TokenDetailsScene.Model.Token.IconState: Equatable {
    typealias SelfType = TokenDetailsScene.Model.Token.IconState
    static func ==(left: SelfType, right: SelfType) -> Bool {
        switch (left, right) {
        case (.loading, .loading),
             (.noIcon, .noIcon):
            return true
        case (.icon(let left), .icon(let right)):
            return left == right
        default:
            return false
        }
    }
}
