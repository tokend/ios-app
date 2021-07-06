import Foundation

public protocol IdentityFetcherProtocol {
    
    func fetchIdentity(
        with phoneNumber: String,
        completion: @escaping ((FetchIdentityResult) -> Void)
    )
}

public enum FetchIdentityResult {
    case existingUser(IdentitiesRepo.Identity)
    case newUser
    case failure
}
