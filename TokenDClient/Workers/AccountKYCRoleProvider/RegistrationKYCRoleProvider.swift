import Foundation
import TokenDSDK

class RegistrationKYCRoleProvider {

    enum FetchAccountRoleError: Swift.Error {
        case noData
    }

    // MARK: - Private properties

    private let keyValuesApi: KeyValuesApiV3
    private let accountType: AccountType
    private let originalAccountId: String

    // MARK: -

    init(
        keyValuesApi: KeyValuesApiV3,
        accountType: AccountType,
        originalAccountId: String
    ) {

        self.keyValuesApi = keyValuesApi
        self.accountType = accountType
        self.originalAccountId = originalAccountId
    }
}

// MARK: - Private methods

private extension RegistrationKYCRoleProvider {

    func fetchAccountRole(
        completion: @escaping (AccountKYCRoleProviderResult) -> Void
    ) {

        let key: String = accountType.userKey

        keyValuesApi.requestKeyValue(
            key: key,
            completion: { (result) in

                switch result {

                case .failure(let error):
                    completion(.failure(error))

                case .success(let document):

                    guard let roleId = document.data?.value?.u32
                        else {
                            completion(.failure(FetchAccountRoleError.noData))
                            return
                    }

                    completion(.success(UInt64(roleId)))
                }
        })
    }
}

// MARK: - AccountKYCRoleProviderProtocol

extension RegistrationKYCRoleProvider: AccountKYCRoleProviderProtocol {

    func fetchRoleId(
        _ completion: @escaping (AccountKYCRoleProviderResult) -> Void
    ) {

        fetchAccountRole(
            completion: completion
        )
    }
}
