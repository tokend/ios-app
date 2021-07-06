import Foundation

enum AccountRoleFetcherError: Swift.Error {
    
    case noIdentity
    case noRole
}

protocol AccountRoleFetcherProtocol {
    
    typealias RoleID = String
    
    func fetchAccountRole(
        login: String,
        completion: @escaping (Result<RoleID, Swift.Error>) -> Void
    )
}
