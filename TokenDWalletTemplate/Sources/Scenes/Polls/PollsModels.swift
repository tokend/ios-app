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
        var assets: [Asset]
        var selectedAsset: Asset?
        var polls: [Poll]
    }
    
    public struct Poll: Equatable {
        let id: String
        let ownerAccountId: String
        let subject: String
        let choices: [Choice]
        var currentChoice: Int?
        
        public struct Choice {
            let name: String
            let value: Int
            let result: Result?
            
            public struct Result {
                let voteCounts: Int
                let totalVotes: Int
            }
        }
        
        public static func == (lhs: Polls.Model.Poll, rhs: Polls.Model.Poll) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    public struct Vote {
        let id: String
        let choice: Int
    }
    
    public enum ActionType {
        case submit
        case remove
    }
    
    public struct Asset: Equatable {
        let code: String
        let ownerAccountId: String
    }
    
    public enum SceneContent {
        case polls([Poll])
        case error(Error)
    }
    
    public enum SceneContentViewModel {
        case polls([Polls.PollCell.ViewModel])
        case empty(String)
    }
    
    public enum LoadingStatus {
        case loaded
        case loading
    }
    
    public enum VoteError: Swift.Error {
        case failedToIdentifyPoll
        case failedToBuildTransaction
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
            let content: Model.SceneContent
            let selectedAsset: Model.Asset
        }
        
        public struct ViewModel {
            let content: Model.SceneContentViewModel
            let asset: String
        }
    }
    
    public enum AssetSelected {
        public struct Request {
            let assetCode: String
            let ownerAccountId: String
        }
    }
    
    public enum ActionButtonClicked {
        public struct Request {
            let pollId: String
            let actionType: Model.ActionType
        }
    }
    
    public enum ChoiceChanged {
        public struct Request {
            let pollId: String
            let choice: Int
        }
    }
    
    public enum Error {
        public struct Response {
            let error: Swift.Error
        }
        public struct ViewModel {
            let message: String
        }
    }
    
    public enum LoadingStatusDidChange {
        public typealias Response = Model.LoadingStatus
        public typealias ViewModel = Response
    }
}
