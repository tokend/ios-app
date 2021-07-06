import Foundation

public protocol ChangeRoleRequestSenderProtocol {
    
    func sendChangeRoleRequest(
        blobId: String,
        roleId: UInt64,
        requestId: UInt64,
        completion: @escaping (Result<Void, Swift.Error>) -> Void
    )
}
