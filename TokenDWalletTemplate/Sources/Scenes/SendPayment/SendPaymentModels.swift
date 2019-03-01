import Foundation

enum SendPayment {
    
    // MARK: - Typealiases
    
    typealias QRCodeReaderCompletion = (_ result: Model.QRCodeReaderResult) -> Void
    typealias SelectContactEmailCompletion = (_ email: String) -> Void
    
    // MARK: -
    
    enum Model {}
    enum Event {}
}

// MARK: - Models

extension SendPayment.Model {
    
    class SceneModel {
        var selectedBalance: BalanceDetails?
        var recipientAddress: String?
        var resolvedRecipientId: String?
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
        }
    }
    
    struct SceneViewModel {
        let selectedBalance: BalanceDetailsViewModel?
        let recipientAddress: String?
        let amount: Decimal
        let amountValid: Bool
    }
    
    struct ViewConfig {
        let recipientAddressFieldTitle: String
        let recipientAddressFieldPlaceholder: String?
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
    
    enum QRCodeReaderResult {
        case canceled
        case success(value: String, metadataType: String)
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

extension SendPayment.Event {
    
    typealias Model = SendPayment.Model
    
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
    
    struct EditRecipientAddress {
        struct Request {
            let address: String?
        }
    }
    
    struct SelectedContact {
        struct Request {
            let email: String
        }
        
        struct Response {
            let sceneModel: Model.SceneModel
            let amountValid: Bool
        }
        
        struct ViewModel {
            let sceneModel: Model.SceneViewModel
        }
    }
    
    struct ScanRecipientQRAddress {
        struct Request {
            let qrResult: Model.QRCodeReaderResult
        }
        
        enum Response {
            case canceled
            case failed(FailedReason)
            case succeeded(sceneModel: Model.SceneModel, amountValid: Bool)
        }
        
        enum ViewModel {
            case canceled
            case failed(errorMessage: String)
            case succeeded(Model.SceneViewModel)
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
}

extension SendPayment.Event.PaymentAction {
    
    enum SendError: Error, LocalizedError {
        case emptyAmount
        case emptyRecipientAddress
        case failedToLoadFees(SendPaymentFeeLoaderResult.FeeLoaderError)
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

extension SendPayment.Event.ScanRecipientQRAddress {
    
    enum FailedReason: Error, LocalizedError {
        case invalidAccountId
        case other(Error)
        case permissionDenied
        
        // MARK: - LocalizedError
        
        var errorDescription: String? {
            switch self {
            case .invalidAccountId:
                return Localized(.invalid_account_id)
            case .other(let error):
                let message = error.localizedDescription
                return Localized(
                    .request_error,
                    replace: [
                        .request_error_replace_message: message
                    ]
                )
            case .permissionDenied:
                return Localized(.permission_denied)
            }
        }
    }
}

// MARK: -

extension SendPayment.Model.ViewConfig {
    
    static func sendPayment() -> SendPayment.Model.ViewConfig {
        return SendPayment.Model.ViewConfig(
            recipientAddressFieldTitle: Localized(.account_id_or_email_colon),
            recipientAddressFieldPlaceholder: Localized(.enter_account_id_or_email)
        )
    }
    
    static func sendWithdraw() -> SendPayment.Model.ViewConfig {
        return SendPayment.Model.ViewConfig(
            recipientAddressFieldTitle: Localized(.destination_address),
            recipientAddressFieldPlaceholder: Localized(.enter_destination_address)
        )
    }
}

extension SendPayment.Model.BalanceDetails: Equatable {
    static func ==(
        left: SendPayment.Model.BalanceDetails,
        right: SendPayment.Model.BalanceDetails
        ) -> Bool {
        
        return left.balanceId == right.balanceId
    }
}
