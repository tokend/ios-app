import Foundation
import TokenDWallet
import TokenDSDK

extension SendPaymentDestination {
    public class WithdrawRecipientAddressResolver: RecipientAddressResolver {
        
        // MARK: - Private properties
        
        private let generalApi: GeneralApi
        
        // MARK: -
        
        init(generalApi: GeneralApi) {
            self.generalApi = generalApi
        }
        
        public func resolve(recipientAddress: String, completion: @escaping (RecipientAddressResolverResult) -> Void) {
            completion(.succeeded(recipientAddress: recipientAddress))
        }
    }
}
