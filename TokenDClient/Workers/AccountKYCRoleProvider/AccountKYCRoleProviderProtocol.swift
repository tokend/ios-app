import Foundation

enum AccountKYCRoleProviderResult {

    case success(_ roleId: UInt64)
    case failure(Swift.Error)
}

protocol AccountKYCRoleProviderProtocol {

    func fetchRoleId(_ completion: @escaping (AccountKYCRoleProviderResult) -> Void)
}
