import Foundation
import TokenDSDK

class LatestChangeRoleRequestProvider {

    struct LastChangeRoleRequest {
        let reviewableRequest: Horizon.ReviewableRequestResource
        let changeRoleRequest: Horizon.ChangeRoleRequestResource
    }

    enum FetchLastChangeRoleRequestError: Swift.Error {
        case apiError(Swift.Error)
        case noChangeRoleRequests
        case noData
        case noRequestDetails
        case wrongRequestDetailsType
    }

    // MARK: - Private properties

    private let accountsApi: AccountsApiV3
    private let originalAccountId: String

    // MARK: -

    init(
        accountsApi: AccountsApiV3,
        originalAccountId: String
    ) {

        self.accountsApi = accountsApi
        self.originalAccountId = originalAccountId
    }
}

// MARK: - Private methods

private extension LatestChangeRoleRequestProvider {

    func fetchLastChangeRoleRequest(
        state: ReviewableRequestState?,
        completion: @escaping (Result<LastChangeRoleRequest, Swift.Error>) -> Void
    ) {
        
        let filters = ChangeRoleRequestsFiltersV3
            .with(.requestor(originalAccountId))
            .addFilterItems([
                "request_details.destination_account": originalAccountId
            ])

        if let state = state,
           state != .unknown {
            filters.addFilterItems(["state": "\(state.rawValue)"])
        }
        
        accountsApi.requestChangeRoleRequests(
            filters: filters,
            include: ["request_details"],
            pagination: .init(.indexedSingle(index: 0, limit: 1, order: .descending)),
            completion: { (result) in

                switch result {

                case .failure(let error):
                    completion(.failure(FetchLastChangeRoleRequestError.apiError(error)))

                case .success(let document):
                    guard let data = document.data
                        else {
                            completion(.failure(FetchLastChangeRoleRequestError.noData))
                            return
                    }
                    if let request = data.first {

                        guard let requestDetails = request.requestDetails
                            else {
                                completion(.failure(FetchLastChangeRoleRequestError.noRequestDetails))
                                return
                        }

                        let type = requestDetails.baseReviewableRequestDetailsRelatedToAccount

                        switch type {

                        case .changeRoleRequest(let changeRole):
                            let lastRequest: LastChangeRoleRequest = .init(
                                reviewableRequest: request,
                                changeRoleRequest: changeRole
                            )
                            completion(.success(lastRequest))

                        case .closeDeferredPaymentRequest,
                             .createDeferredPaymentRequest,
                             .createPollRequest,
                             .dataCreationRequest,
                             .kYCRecoveryRequest,
                             .redemptionRequest,
                             .`self`:
                            completion(.failure(FetchLastChangeRoleRequestError.wrongRequestDetailsType))
                        }

                    } else {
                        completion(.failure(FetchLastChangeRoleRequestError.noChangeRoleRequests))
                    }
                }
        })
    }
}

// MARK: - AccountKYCRoleProviderProtocol

extension LatestChangeRoleRequestProvider {

    func fetchLatest(
        state: ReviewableRequestState? = nil,
        _ completion: @escaping (Result<LastChangeRoleRequest, Swift.Error>) -> Void
    ) {

        fetchLastChangeRoleRequest(
            state: state,
            completion: completion
        )
    }
}
