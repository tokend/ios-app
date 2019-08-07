import UIKit

enum ExploreTokensScene {
    
    // MARK: - Typealiases
    
    typealias TokenIdentifier = String
    
    // MARK: -
    
    enum Model {}
    enum Event {}
}

extension ExploreTokensScene.Model {
    struct Token {
        let identifier: ExploreTokensScene.TokenIdentifier
        
        let iconUrl: URL?
        let code: String
        let name: String?
        
        let balanceState: BalanceState
    }
    
    struct SceneModel {
        var tokens: [Token]
        var filter: String
    }
    
    struct TableSection {
        let cells: [ExploreTokensTableViewCell.Model]
    }
}

extension ExploreTokensScene.Model.Token {
    enum BalanceState {
        case creating
        case created(id: String)
        case notCreated
    }
}

extension ExploreTokensScene.Model.Token {
    enum IconState {
        case loading
        case icon(UIImage)
        case noIcon
    }
}

extension ExploreTokensScene.Model.Token.IconState: Equatable {
    typealias SelfType = ExploreTokensScene.Model.Token.IconState
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

extension ExploreTokensScene.Event {
    enum DidInitiateRefresh {
        struct Request { }
    }
    
    enum ViewDidLoad {
        struct Request {}
    }
    
    enum TokensDidChange {
        struct Response {
            let tokens: [ExploreTokensScene.Model.Token]
        }
        enum ViewModel {
            case empty(title: String)
            case sections([ExploreTokensScene.Model.TableSection])
        }
    }
    
    enum LoadingStatusDidChange {
        typealias Response = ExploreTokensScene.TokensFetcherProtocol.LoadingStatus
        enum ViewModel {
            case loading
            case loaded
        }
    }
    
    enum Error {
        struct Response {
            let error: Swift.Error
        }
        
        struct ViewModel {
            let message: String
        }
    }
    
    enum DidSelectAction {
        enum Action {
            case viewHistory(balanceId: String)
        }
        
        struct Request {
            let identifier: ExploreTokensScene.TokenIdentifier
        }
        typealias Response = Action
        typealias ViewModel = Action
    }
    
    enum DidFilter {
        struct Request {
            let filter: String
        }
    }
    
    enum ViewDidAppear {
        struct Request { }
    }
    
    enum ViewWillDisappear {
        struct Request { }
    }
}
