import Foundation

enum SendPaymentAmount {
    
    // MARK: -
    
    enum Model {}
    enum Event {}
}

// MARK: - Models

extension SendPaymentAmount.Model {
    
    class SceneModel {
        var selectedBalance: BalanceDetails?
        var recipientAddress: String?
        var resolvedRecipientId: String?
        let recipientAccountId: String
        var amount: Decimal = 0.0
        let operation: Operation
        let feeType: FeeType
        init(
            feeType: FeeType,
            operation: Operation,
            recipientAddress: String? = nil
            ) {
            self.operation = operation
            self.recipientAddress = recipientAddress
            self.feeType = feeType
            self.recipientAccountId = "GAA7XZQOYZ6YU5QQGEZUFEWSNL4QJT3V5F5GNCHUVWVNE4CVCSY4L4N7"
        }
    }
    
    struct SceneViewModel {
        let selectedBalance: BalanceDetailsViewModel?
        let recipientAddress: String?
        let amount: Decimal
        let amountValid: Bool
    }
    
    struct BalanceDetails {
        let asset: String
        let balance: Decimal
        let balanceId: String
    }
    
    struct BalanceDetailsViewModel {
        let asset: String
        let balance: String
        let balanceId: String
    }
    
    struct FeeModel {
        let asset: String
        let fixed: Decimal
        let percent: Decimal
    }
    
    struct SendPaymentModel {
        let senderBalanceId: String
        let asset: String
        let amount: Decimal
        let recipientNickname: String
        let recipientAccountId: String
        let senderFee: FeeModel
        let recipientFee: FeeModel
        let reference: String
    }
    
    struct SendWithdrawModel {
        let senderBalanceId: String
        let asset: String
        let amount: Decimal
        let recipientNickname: String
        let recipientAddress: String
        let senderFee: FeeModel
    }
    
    enum Operation {
        case handleSend
        case handleWithdraw
    }
    
    enum FeeType {
        case payment
        case offer
        case withdraw
    }
}

// MARK: - Events

extension SendPaymentAmount.Event {
    
    typealias Model = SendPaymentAmount.Model
    
    struct ViewDidLoad {
        struct Request {}
        
        struct Response {
            let sceneModel: Model.SceneModel
            let amountValid: Bool
        }
        
        struct ViewModel {
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
    
    enum FeeUpdated {
        struct Response {
            let fee: Model.FeeModel
        }
        struct ViewModel {
            let fee: String
        }
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
    static func ==(
        left: SendPaymentAmount.Model.BalanceDetails,
        right: SendPaymentAmount.Model.BalanceDetails
        ) -> Bool {
        
        return left.balanceId == right.balanceId
    }
}
