import Foundation
import TokenDSDK

class IdentityFetcher {
    
    // MARK: - Private properties
    
    private let identitiesRepo: IdentitiesRepo
    
    init(
        identitiesRepo: IdentitiesRepo
    ) {
        self.identitiesRepo = identitiesRepo
    }
}

extension IdentityFetcher: IdentityFetcherProtocol {
    
    func fetchIdentity(
        with phoneNumber: String,
        completion: @escaping ((FetchIdentityResult) -> Void)
    ) {
        
        identitiesRepo.requestIdentity(
            withPhoneNumber: phoneNumber,
            completion: { (result) in
                
                switch result {
                
                case .success(let identity):
                    if let identity = identity {
                        completion(.existingUser(identity))
                    } else {
                        completion(.newUser)
                    }

                case .failure(let error):
                    
                    if error is ApiError {
                        if error.contains(status: "404") {
                            completion(.newUser)
                        } else {
                            completion(.failure)
                        }
                    }

                    completion(.newUser)
                }
            }
        )
    }
}
