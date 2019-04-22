import UIKit

public enum SendPaymentDestination {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    typealias QRCodeReaderCompletion = (_ result: Model.QRCodeReaderResult) -> Void
    typealias SelectContactEmailCompletion = (_ email: String) -> Void
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension SendPaymentDestination.Model {
    
    public struct SceneModel {
        var address: String?
        var accountId: String?
    }
    
    public enum QRCodeReaderResult {
        case canceled
        case success(value: String, metadataType: String)
    }
    
    public struct ViewConfig {
        let recipientAddressFieldTitle: String
        let recipientAddressFieldPlaceholder: String?
    }
    
}

// MARK: - Events

extension SendPaymentDestination.Event {
    public typealias Model = SendPaymentDestination.Model
    
    // MARK: -
    
    public enum ViewDidLoad {
        public struct Request {}
        public struct Response {}
        public struct ViewModel {}
    }
    
    public struct EditRecipientAddress {
        public struct Request {
            let address: String?
        }
    }
    
    public struct SelectedContact {
        public struct Request {
            public let email: String
        }
        
        public struct Response {
            public let email: String
        }
        
        public struct ViewModel {
            public let email: String
        }
    }
    
    public struct ScanRecipientQRAddress {
        public struct Request {
            public let qrResult: Model.QRCodeReaderResult
        }
        
        public enum Response {
            case canceled
            case failed(FailedReason)
            case succeeded(String)
        }
        
        public enum ViewModel {
            case canceled
            case failed(errorMessage: String)
            case succeeded(String)
        }
    }
}

extension SendPaymentDestination.Event.ScanRecipientQRAddress {
    
    public enum FailedReason: Error, LocalizedError {
        case invalidAccountId
        case other(Error)
        case permissionDenied
        
        // MARK: - LocalizedError
        
        public var errorDescription: String? {
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

extension SendPaymentDestination.Model.ViewConfig {
    
    static func sendPayment() -> SendPaymentDestination.Model.ViewConfig {
        return SendPaymentDestination.Model.ViewConfig(
            recipientAddressFieldTitle: Localized(.account_id_or_email_colon),
            recipientAddressFieldPlaceholder: Localized(.enter_account_id_or_email)
        )
    }
    
    static func sendWithdraw() -> SendPaymentDestination.Model.ViewConfig {
        return SendPaymentDestination.Model.ViewConfig(
            recipientAddressFieldTitle: Localized(.destination_address),
            recipientAddressFieldPlaceholder: Localized(.enter_destination_address)
        )
    }
}
