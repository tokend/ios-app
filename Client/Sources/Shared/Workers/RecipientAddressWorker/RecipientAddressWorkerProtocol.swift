import Foundation

public protocol RecipientAddressWorkerProtocol {
    
    func processRecipientAddress(
        with value: String,
        completion: @escaping (Result<RecipientAddress, Swift.Error>) -> Void
    )
}

public struct RecipientAddress {
    let accountId: String
    let email: String?
}
