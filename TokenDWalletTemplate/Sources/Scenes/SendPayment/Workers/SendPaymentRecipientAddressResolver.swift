import Foundation
import TokenDWallet
import TokenDSDK

enum RecipientAddressResolverResult {
    enum AddressResolveError: Swift.Error, LocalizedError {
        case invalidAccountIdOrEmail
        case other(ApiErrors)
        
        var errorDescription: String? {
            switch self {
            case .invalidAccountIdOrEmail:
                return Localized(.invalid_account_id_or_email)
            case .other(let errors):
                let message = errors.localizedDescription
                return Localized(
                    .request_error,
                    replace: [
                        .request_error_replace_message: message
                    ]
                )
            }
        }
    }
    
    case succeeded(recipientAddress: String)
    case failed(AddressResolveError)
}

protocol SendPaymentRecipientAddressResolverProtocol {
    func resolve(
        recipientAddress: String,
        completion: @escaping (_ result: RecipientAddressResolverResult) -> Void
    )
}

extension SendPayment {
    typealias RecipientAddressResolver = SendPaymentRecipientAddressResolverProtocol
    
    class RecipientAddressResolverWorker: RecipientAddressResolver {
        
        // MARK: - Private properties
        
        private let generalApi: GeneralApi
        
        // MARK: -
        
        init(generalApi: GeneralApi) {
            self.generalApi = generalApi
        }
        
        // MARK: - RecipientAddressResolver
        
        func resolve(
            recipientAddress: String,
            completion: @escaping (_ result: RecipientAddressResolverResult) -> Void
            ) {
            
            // Try to derive account id from address string
            
            do {
                _ = try Base32Check.decodeCheck(
                    expectedVersion: .accountIdEd25519,
                    encoded: recipientAddress
                )
                completion(.succeeded(recipientAddress: recipientAddress))
            } catch {
                let email = recipientAddress.lowercased()
                self.requestDataByEmail(email, completion: completion)
            }
        }
        
        // MARK: - Private
        
        private func requestDataByEmail(
            _ email: String,
            completion: @escaping (_ result: RecipientAddressResolverResult) -> Void
            ) {
            
            guard self.validateEmail(email) else {
                completion(.failed(.invalidAccountIdOrEmail))
                return
            }
            
            self.generalApi.requestAccountId(email: email, completion: { (result) in
                switch result {
                    
                case .failed(let error):
                    completion(.failed(.other(error)))
                    
                case .succeeded(let response):
                    guard let identity = response.first(where: { (identity) -> Bool in
                        return identity.attributes.email == email
                    }) else {
                        completion(.failed(.invalidAccountIdOrEmail))
                        return
                    }
                    
                    completion(.succeeded(recipientAddress: identity.attributes.address))
                }
            })
        }
        
        private func validateEmail(_ email: String) -> Bool {
            return true
        }
    }
}
