import Foundation
import TokenDSDK

class EditKYCRoleProvider {

    enum FetchLastChangeRoleRequestError: Swift.Error {
        case other(Swift.Error)
        case wrongRequestDetailsType
    }
    enum FetchAccountRoleError: Swift.Error {
        case apiError(Swift.Error)
        case noData
        case noRoleIdentifier
        case wrongRoleIdentifierType
    }

    // MARK: - Private properties

    private let accountsApi: AccountsApiV3
    private let lastChangeRoleRequestProvider: LatestChangeRoleRequestProvider
    private let originalAccountId: String

    // MARK: -

    init(
        accountsApi: AccountsApiV3,
        lastChangeRoleRequestProvider: LatestChangeRoleRequestProvider,
        originalAccountId: String
    ) {

        self.accountsApi = accountsApi
        self.lastChangeRoleRequestProvider = lastChangeRoleRequestProvider
        self.originalAccountId = originalAccountId
    }
}

// MARK: - Private methods

private extension EditKYCRoleProvider {

    func fetchLastChangeRoleRequest(
        completion: @escaping (AccountKYCRoleProviderResult) -> Void
    ) {

        lastChangeRoleRequestProvider.fetchLatest(
            { [weak self] (result) in

                switch result {

                case .failure(let error):
                    completion(.failure(FetchLastChangeRoleRequestError.other(error)))

                case .success(let request):

                    if request.reviewableRequest.stateValue.isToUpdate {

                        completion(.success(request.changeRoleRequest.accountRoleToSet))
                    } else {

                        self?.fetchAccountRole(
                            completion: completion
                        )
                    }
                }
        })
    }

    func fetchAccountRole(
        completion: @escaping (AccountKYCRoleProviderResult) -> Void
    ) {

        accountsApi.requestAccount(
            accountId: originalAccountId,
            include: nil,
            pagination: nil,
            completion: { (result) in

                switch result {

                case .failure(let error):
                    completion(.failure(FetchAccountRoleError.apiError(error)))

                case .success(let document):
                    guard let data = document.data
                        else {
                            completion(.failure(FetchAccountRoleError.noData))
                            return
                    }

                    guard let role = data.role?.id
                        else {
                            completion(.failure(FetchAccountRoleError.noRoleIdentifier))
                            return
                    }

                    guard let roleId = UInt64(role)
                        else {
                            completion(.failure(FetchAccountRoleError.wrongRoleIdentifierType))
                            return
                    }

                    completion(.success(roleId))
                }
        })
    }
}

// MARK: - AccountKYCRoleProviderProtocol

extension EditKYCRoleProvider: AccountKYCRoleProviderProtocol {

    func fetchRoleId(
        _ completion: @escaping (AccountKYCRoleProviderResult) -> Void
    ) {

        fetchLastChangeRoleRequest(
            completion: completion
        )
    }
}
