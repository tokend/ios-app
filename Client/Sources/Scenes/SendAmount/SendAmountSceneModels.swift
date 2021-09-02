import UIKit

public enum SendAmountScene {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension SendAmountScene.Model {
    
    struct SceneModel {
        let recipientAddress: String
        var description: String?
        var amount: String?
        var selectedBalanceId: Balance.Identifier
        var balancesList: [Balance]
    }
    
    struct SceneViewModel {
        let recipientAddress: String
        let amount: String?
        let assetCode: String
        let fee: String
        let description: String?
    }
    
    public struct Balance {
        typealias Identifier = String
        
        let id: Identifier
        let assetCode: String
        let amount: Decimal
    }
}

// MARK: - Events

extension SendAmountScene.Event {
    
    public typealias Model = SendAmountScene.Model
    
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
    
    public enum DidEnterAmountSync {
        public struct Request {
            let value: String?
        }
    }
    
    public enum DidSelectBalanceSync {
        public struct Request {}
    }
    
    public enum DidEnterDescriptionSync {
        public struct Request {
            let value: String?
        }
    }
    
    public enum DidTapContinueSync {
        public struct Request {}
        
        public struct Response {
            let recipient: String
        }
        public typealias ViewModel = Response
    }
}
