import Foundation

enum SendPayment {
    
    // MARK: - Typealiases
    
    typealias QRCodeReaderCompletion = (_ result: Model.QRCodeReaderResult) -> Void
    
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
    struct ViewDidLoad {
        struct Request {}
        
        struct Response {
            let sceneModel: SendPayment.Model.SceneModel
            let amountValid: Bool
        }
        
        struct ViewModel {
            let sceneModel: SendPayment.Model.SceneViewModel
        }
    }
    
    struct LoadBalances {
        struct Request {}
        enum Response {
            case loading
            case loaded
            case failed(Error)
            case succeeded(sceneModel: SendPayment.Model.SceneModel, amountValid: Bool)
        }
        
        enum ViewModel {
            case loading
            case loaded
            case failed(errorMessage: String)
            case succeeded(SendPayment.Model.SceneViewModel)
        }
    }
    
    struct SelectBalance {
        struct Request {}
        
        struct Response {
            let balances: [SendPayment.Model.BalanceDetails]
        }
        
        struct ViewModel {
            let balances: [SendPayment.Model.BalanceDetailsViewModel]
        }
    }
    
    struct BalanceSelected {
        struct Request {
            let balanceId: String
        }
        
        struct Response {
            let sceneModel: SendPayment.Model.SceneModel
            let amountValid: Bool
        }
        
        struct ViewModel {
            let sceneModel: SendPayment.Model.SceneViewModel
        }
    }
    
    struct EditRecipientAddress {
        struct Request {
            let address: String?
        }
    }
    
    struct ScanRecipientQRAddress {
        struct Request {
            let qrResult: SendPayment.Model.QRCodeReaderResult
        }
        
        enum Response {
            case canceled
            case failed(FailedReason)
            case succeeded(sceneModel: SendPayment.Model.SceneModel, amountValid: Bool)
        }
        
        enum ViewModel {
            case canceled
            case failed(errorMessage: String)
            case succeeded(SendPayment.Model.SceneViewModel)
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
            case failed(SendPayment.Event.PaymentAction.SendError)
            case succeeded(SendPayment.Model.SendWithdrawModel)
        }
        
        enum ViewModel {
            case loading
            case loaded
            case failed(errorMessage: String)
            case succeeded(SendPayment.Model.SendWithdrawModel)
        }
    }
    
    struct PaymentAction {
        enum Response {
            case loading
            case loaded
            case failed(SendError)
            case succeeded(SendPayment.Model.SendPaymentModel)
        }
        
        enum ViewModel {
            case loading
            case loaded
            case failed(errorMessage: String)
            case succeeded(SendPayment.Model.SendPaymentModel)
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
                return "Empty amount"
            case .emptyRecipientAddress:
                return "Empty recipient address"
            case .failedToLoadFees(let error):
                return "Failed to load fees: \(error.localizedDescription)"
            case .failedToResolveRecipientAddress(let error):
                return "Failed to resolve recipient address: \(error.localizedDescription)"
            case .insufficientFunds:
                return "Insufficient funds"
            case .noBalance:
                return "No balance"
            case .other(let error):
                return "Request error: \(error.localizedDescription)"
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
                return "Invalid account id"
            case .other(let error):
                return "Request error: \(error.localizedDescription)"
            case .permissionDenied:
                return "Permission denied"
            }
        }
    }
}

// MARK: -

extension SendPayment.Model.ViewConfig {
    static func sendPayment() -> SendPayment.Model.ViewConfig {
        return SendPayment.Model.ViewConfig(
            recipientAddressFieldTitle: "Account ID or email:",
            recipientAddressFieldPlaceholder: "Enter Account ID or email"
        )
    }
    
    static func sendWithdraw() -> SendPayment.Model.ViewConfig {
        return SendPayment.Model.ViewConfig(
            recipientAddressFieldTitle: "Destination address:",
            recipientAddressFieldPlaceholder: "Enter destination address"
        )
    }
}

extension SendPayment.Model.BalanceDetails: Equatable {
    static func ==(left: SendPayment.Model.BalanceDetails, right: SendPayment.Model.BalanceDetails) -> Bool {
        return left.balanceId == right.balanceId
    }
}
