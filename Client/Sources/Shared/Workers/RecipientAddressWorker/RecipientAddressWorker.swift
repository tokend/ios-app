import Foundation

class RecipientAddressWorker {
    
    private let identitiesRepo: IdentitiesRepo
}

extension RecipientAddressWorker: RecipientAddressWorkerProtocol {
    
    func processRecipientAddress(
        with value: String,
        completion: @escaping (Result<RecipientAddress, Error>) -> Void
    ) {
        
        // check if accountId
        
        // if yes, completion
        
        // if no, check if email, go to api
    }
}
