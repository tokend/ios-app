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
                return "Invalid account id or email"
            case .other(let errors):
                return "Request error: \(errors.localizedDescription)"
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
                self.requestDataByEmail(recipientAddress, completion: completion)
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
                    switch error {
                        
                    case .wrongEmail:
                        completion(.failed(.invalidAccountIdOrEmail))
                        
                    case .other(let errors):
                        completion(.failed(.other(errors)))
                    }
                    
                case .succeeded(let response):
                    completion(.succeeded(recipientAddress: response.accountId))
                }
            })
        }
        
        private func validateEmail(_ email: String) -> Bool {
            return true
        }
    }
}
