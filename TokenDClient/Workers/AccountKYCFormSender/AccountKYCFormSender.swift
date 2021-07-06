import Foundation
import TokenDSDK
import TokenDWallet

class AccountKYCFormSender {

    enum FetchLastChangeRoleRequestError: Swift.Error {
        case other(Swift.Error)
        case noIdentifier
        case wrongIdentifierType
    }
    enum SendBlobError: Swift.Error {
        case failedToEncodeBlob(Swift.Error)
        case failedToFormBlobJSON
        case apiError(Swift.Error)
    }

    // MARK: - Private properties

    private let blobsApi: BlobsApi
    private let accountsApi: AccountsApiV3
    private let lastChangeRoleRequestProvider: LatestChangeRoleRequestProvider
    private let kycFormEncoder: AccountKYCFormEncoder
    private let changeRoleRequestSender: ChangeRoleRequestSenderProtocol
    private let originalAccountId: String

    // MARK: -

    init(
        blobsApi: BlobsApi,
        accountsApi: AccountsApiV3,
        lastChangeRoleRequestProvider: LatestChangeRoleRequestProvider,
        kycFormEncoder: AccountKYCFormEncoder,
        changeRoleRequestSender: ChangeRoleRequestSenderProtocol,
        originalAccountId: String
        ) {

        self.blobsApi = blobsApi
        self.accountsApi = accountsApi
        self.lastChangeRoleRequestProvider = lastChangeRoleRequestProvider
        self.kycFormEncoder = kycFormEncoder
        self.changeRoleRequestSender = changeRoleRequestSender
        self.originalAccountId = originalAccountId
    }
}

// MARK: - Private methods

private extension AccountKYCFormSender {

    func fetchLastChangeRoleRequest(
        _ form: AccountKYCForm,
        roleId: UInt64,
        completion: @escaping (AccountKYCFormSenderResult) -> Void
    ) {

        lastChangeRoleRequestProvider.fetchLatest(
            { [weak self] (result) in

                switch result {

                case .failure(let error):

                    switch error {

                    case let changeRoleError as LatestChangeRoleRequestProvider.FetchLastChangeRoleRequestError:

                        switch changeRoleError {

                        case .noChangeRoleRequests:
                            self?.sendBlob(
                                form: form,
                                roleId: roleId,
                                requestId: 0,
                                completion: completion
                            )
                            return

                        case .apiError,
                             .noData,
                             .noRequestDetails,
                             .wrongRequestDetailsType:
                            break
                        }

                    default:
                        break
                    }
                    completion(.failure(FetchLastChangeRoleRequestError.other(error)))

                case .success(let request):

                    if request.reviewableRequest.stateValue.isToUpdate {
                        guard let id = request.reviewableRequest.id
                            else {
                                completion(.failure(FetchLastChangeRoleRequestError.noIdentifier))
                                return
                        }

                        guard let requestId = UInt64(id)
                            else {
                                completion(.failure(FetchLastChangeRoleRequestError.wrongIdentifierType))
                                return
                        }

                        self?.sendBlob(
                            form: form,
                            roleId: roleId,
                            requestId: requestId,
                            completion: completion
                        )
                    } else {
                        self?.sendBlob(
                            form: form,
                            roleId: roleId,
                            requestId: 0,
                            completion: completion
                        )
                    }
                }
        })
    }

    func sendBlob(
        form: AccountKYCForm,
        roleId: UInt64,
        requestId: UInt64,
        completion: @escaping(AccountKYCFormSenderResult) -> Void
        ) {

        kycFormEncoder.encodeKYCForm(
            form,
            completion: { [weak self] (result) in

                switch result {

                case .failure(let error):
                    completion(.failure(error))

                case .success(let jsonString):
                    guard let self = self
                        else {
                            completion(.failure(SendBlobError.failedToFormBlobJSON))
                            return
                    }
                    self.blobsApi.postBlob(
                        type: BlobType.kycForm.rawValue,
                        value: jsonString,
                        ownerAccountId: self.originalAccountId,
                        completion: { [weak self] (result) in

                            switch result {

                            case .failure(let error):
                                completion(.failure(SendBlobError.apiError(error)))

                            case .success(let blobResponse):
                                self?.changeRoleRequestSender.sendChangeRoleRequest(
                                    blobId: blobResponse.id,
                                    roleId: roleId,
                                    requestId: requestId,
                                    completion: { (result) in
                                        
                                        switch result {
                                        
                                        case .success:
                                            completion(.success)
                                        case .failure(let error):
                                            completion(.failure(error))
                                        }
                                    }
                                )
                            }
                        }
                    )
                }
        })
    }
}

extension AccountKYCFormSender: AccountKYCFormSenderProtocol {

    func sendKYCForm(
        _ form: AccountKYCForm,
        roleId: UInt64,
        completion: @escaping (AccountKYCFormSenderResult) -> Void
    ) {

        fetchLastChangeRoleRequest(
            form,
            roleId: roleId,
            completion: completion
        )
    }
}

private let snakeCaseEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    return encoder
}()
