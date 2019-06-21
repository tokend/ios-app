import UIKit

public enum Polls {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension Polls.Model {
    
    public struct SceneModel {
        var balances: [Balance]
        var selectedBalance: Balance?
        var polls: [Poll]
    }
    
    public struct Balance: Equatable {
        let asset: String
        let balanceId: String
    }
    
    public struct Poll {
        let id: String
        let ownerAccountId: String
        let subject: String
        let choices: [Choice]
        let currentChoice: Int?
        
        public struct Choice {
            let name: String
            let result: Result?
            
            public struct Result {
                let voteCounts: Int
                let totalVotes: Int
            }
        }
    }
    
    public struct Vote {
        let id: String
        let choice: Int
    }
    
    public enum ButtonType {
        case submit
        case remove
    }
    
    public enum LoadingStatus {
        case loaded
        case loading
    }
}

// MARK: - Events

extension Polls.Event {
    public typealias Model = Polls.Model
    
    // MARK: -
    
    public enum ViewDidLoad {
        public struct Request {}
    }
    
    public enum SceneUpdated {
        public struct Response {
            let polls: [Model.Poll]
            let selectedBalance: Model.Balance
        }
        
        public struct ViewModel {
            let polls: [Polls.PollCell.ViewModel]
            let asset: String
        }
    }
    
    public enum SelectBalance {
        public struct Request {}
        
        public struct Response {
            let balances: [Model.Balance]
        }
        
        public struct ViewModel {
            let assets: [String]
        }
    }
    
    public enum BalanceSelected {
        public struct Request {
            let balanceId: String
        }
    }
}
