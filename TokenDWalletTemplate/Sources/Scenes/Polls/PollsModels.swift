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
    
    public struct Asset: Equatable {
        let code: String
        let ownerAccountId: String
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
            let selectedAsset: Model.Asset
        }
        
        public struct ViewModel {
            let polls: [Polls.PollCell.ViewModel]
            let asset: String
        }
    }
    
    public enum AssetSelected {
        public struct Request {
            let ownerAccountId: String
        }
    }
}
