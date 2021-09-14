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
        var selectedBalance: Balance
        let recipientAddress: String
        var description: String?
        var enteredAmount: Decimal?
        var enteredAmountError: EnteredAmountValidationError?
        var feesForEnteredAmount: Fees?
        var isPayingFeeForRecipient: Bool
        var feesLoadingStatus: LoadingStatus
    }
    
    struct SceneViewModel {
        let recipientAddress: String
        let availableBalance: String
        let amountContext: AmountTextField.Context
        let enteredAmount: Decimal?
        let enteredAmountError: String?
        let assetCode: String
        let description: String?
        let senderFeeModel: FeeAmountView.ViewModel?
        let recipientFeeModel: FeeAmountView.ViewModel?
        let feeSwitcherModel: FeeSwitcherView.ViewModel?
        let feeIsLoading: Bool
    }
    
    public struct Balance {
        typealias Identifier = String
        
        let id: Identifier
        let assetCode: String
        let amount: Decimal
    }
    
    public struct Fees {
        let senderFee: Decimal
        let recipientFee: Decimal
    }
    
    public enum EnteredAmountValidationError: Swift.Error {
        case emptyString
        case notEnoughBalance
        case cannotBeZero
    }
    
    public enum LoadingStatus {
        case loading
        case loaded
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
            let value: Decimal?
        }
    }
    
    public enum DidEnterDescriptionSync {
        public struct Request {
            let value: String?
        }
    }
    
    public enum DidSwitchPayFeeForRecipientSync {
        public struct Request {
            let value: Bool
        }
    }
    
    public enum DidTapContinueSync {
        public struct Request {}
        
        public struct Response {
            let amount: Decimal
            let assetCode: String
            let isPayingFeeForRecipient: Bool
            let description: String?
        }
        public typealias ViewModel = Response
    }
}
