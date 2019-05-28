import Foundation

public enum SendPaymentAmount {
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

public extension SendPaymentAmount.Model {
    
   public class SceneModel {
        public var selectedBalance: BalanceDetails?
        public var senderFee: FeeModel?
        public var recipientAddress: String?
        public var resolvedRecipientId: String?
        public var description: String?
        public var amount: Decimal = 0.0
        public let operation: Operation
        public let feeType: FeeType
    
        init(
            feeType: FeeType,
            operation: Operation,
            recipientAddress: String? = nil
            ) {
            
            self.operation = operation
            self.recipientAddress = recipientAddress
            self.feeType = feeType
        }
    }
    
    public struct ViewConfig {
        let descriptionIsHidden: Bool
        let actionButtonTitle: NSAttributedString
    }
    
    public struct SceneViewModel {
        let selectedBalance: BalanceDetailsViewModel?
        let recipientAddress: String?
        let amount: Decimal
        let amountValid: Bool
    }
    
    public struct BalanceDetails {
        public let asset: String
        public let balance: Decimal
        public let balanceId: String
    }
    
    public struct BalanceDetailsViewModel {
        public let asset: String
        public let balance: String
        public let balanceId: String
    }
    
    public struct FeeModel {
        public let asset: String
        public let fixed: Decimal
        public let percent: Decimal
    }
    
    public struct SendPaymentModel {
        public let senderBalanceId: String
        public let asset: String
        public let amount: Decimal
        public let recipientNickname: String
        public let recipientAccountId: String
        public let senderFee: FeeModel
        public let recipientFee: FeeModel
        public let description: String
        public let reference: String
    }
    
    public struct SendWithdrawModel {
        public let senderBalance: BalanceDetails
        public let asset: String
        public let amount: Decimal
        public let senderFee: FeeModel
    }
    
    public enum Operation {
        case handleSend
        case handleWithdraw
    }
    
    public enum FeeType {
        case payment
        case offer
        case withdraw
    }
    
    public struct FeeOverviewModel {
        let asset: String
    }
}

// MARK: - Events

extension SendPaymentAmount.Event {
    
    public typealias Model = SendPaymentAmount.Model
    
    struct ViewDidLoad {
        struct Request {}
        
        struct Response {
            let sceneModel: Model.SceneModel
            let amountValid: Bool
        }
        
        struct ViewModel {
            let recipientInfo: String
            let sceneModel: Model.SceneViewModel
        }
    }
    
    struct LoadBalances {
        struct Request {}
        enum Response {
            case loading
            case loaded
            case failed(Error)
            case succeeded(sceneModel: Model.SceneModel, amountValid: Bool)
        }
        
        enum ViewModel {
            case loading
            case loaded
            case failed(errorMessage: String)
            case succeeded(Model.SceneViewModel)
        }
    }
    
    struct SelectBalance {
        struct Request {}
        
        struct Response {
            let balances: [Model.BalanceDetails]
        }
        
        struct ViewModel {
            let balances: [Model.BalanceDetailsViewModel]
        }
    }
    
    struct BalanceSelected {
        struct Request {
            let balanceId: String
        }
        
        struct Response {
            let sceneModel: Model.SceneModel
            let amountValid: Bool
        }
        
        struct ViewModel {
            let sceneModel: Model.SceneViewModel
        }
    }
    
    struct EditAmount {
        struct Request {
            let amount: Decimal
        }
        
        struct Response {
            let amountValid: Bool
        }
        
        struct ViewModel {
            let amountValid: Bool
        }
    }
    
    struct DescriptionUpdated {
        struct Request {
            let description: String?
        }
    }
    
    struct SubmitAction {
        struct Request {}
    }
    
    struct WithdrawAction {
        enum Response {
            case loading
            case loaded
            case failed(PaymentAction.SendError)
            case succeeded(Model.SendWithdrawModel)
        }
        
        enum ViewModel {
            case loading
            case loaded
            case failed(errorMessage: String)
            case succeeded(Model.SendWithdrawModel)
        }
    }
    
    struct PaymentAction {
        enum Response {
            case loading
            case loaded
            case failed(SendError)
            case succeeded(Model.SendPaymentModel)
        }
        
        enum ViewModel {
            case loading
            case loaded
            case failed(errorMessage: String)
            case succeeded(Model.SendPaymentModel)
        }
    }
    
    struct FeeOverviewAvailability {
        struct Response {
            let available: Bool
        }
        typealias ViewModel = Response
    }
    
    struct FeeOverviewAction {
        struct Request {}
        struct Response {
            let asset: String
            let feeType: Int32
        }
        typealias ViewModel = Response
    }
}

extension SendPaymentAmount.Event.PaymentAction {
    
    enum SendError: Error, LocalizedError {
        case emptyAmount
        case emptyRecipientAddress
        case failedToLoadFees(SendPaymentAmountFeeLoaderResult.FeeLoaderError)
        case failedToResolveRecipientAddress(RecipientAddressResolverResult.AddressResolveError)
        case insufficientFunds
        case noBalance
        case other(Error)
        
        // MARK: - LocalizedError
        
        var errorDescription: String? {
            switch self {
            case .emptyAmount:
                return Localized(.empty_amount)
            case .emptyRecipientAddress:
                return Localized(.empty_recipient_address)
            case .failedToLoadFees(let error):
                let message = error.localizedDescription
                return Localized(
                    .failed_to_load_fees,
                    replace: [
                        .failed_to_load_fees_replace_message: message
                    ]
                )

            case .failedToResolveRecipientAddress(let error):
                let message = error.localizedDescription
                return Localized(
                    .failed_to_resolve_recipient_address,
                    replace: [
                        .failed_to_resolve_recipient_address_replace_message: message
                    ]
                )

            case .insufficientFunds:
                return Localized(.insufficient_funds)
            case .noBalance:
                return Localized(.no_balance)
            case .other(let error):
                let message = error.localizedDescription
                return Localized(
                    .request_error,
                    replace: [
                        .request_error_replace_message: message
                    ]
                )
            }
        }
    }
}

// MARK: -

extension SendPaymentAmount.Model.BalanceDetails: Equatable {
    public static func ==(
        left: SendPaymentAmount.Model.BalanceDetails,
        right: SendPaymentAmount.Model.BalanceDetails
        ) -> Bool {
        
        return left.balanceId == right.balanceId
    }
}

extension SendPaymentAmount.Model.ViewConfig {
    
    static func sendPaymentViewConfig() -> SendPaymentAmount.Model.ViewConfig {
        let actionButtonTitle = NSAttributedString(
            string: Localized(.confirm),
            attributes: [
                .font: Theme.Fonts.actionButtonFont,
                .foregroundColor: Theme.Colors.textOnAccentColor
            ]
        )
        
        return SendPaymentAmount.Model.ViewConfig(
            descriptionIsHidden: false,
            actionButtonTitle: actionButtonTitle
        )
    }
    
    static func withdrawViewConfig() -> SendPaymentAmount.Model.ViewConfig {
        let actionButtonTitle = NSAttributedString(
            string: Localized(.continue_capitalized),
            attributes: [
                .font: Theme.Fonts.actionButtonFont,
                .foregroundColor: Theme.Colors.textOnAccentColor
            ]
        )
        
        return SendPaymentAmount.Model.ViewConfig(
            descriptionIsHidden: true,
            actionButtonTitle: actionButtonTitle
        )
    }
}
