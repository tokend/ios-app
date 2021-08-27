import Foundation

public protocol RecipientAddressProcessorProtocol {
    
    func processRecipientAddress(
        with value: String,
        completion: @escaping (Result<RecipientAddress, Swift.Error>) -> Void
    )
}

public struct RecipientAddress {
    let accountId: String
    let email: String?
}
