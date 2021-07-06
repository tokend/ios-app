import Foundation
import TokenDSDK

class FCMTokenUploader {

    private struct FCMToken: Encodable {

        let data: Data

        struct Data: Encodable {

            let attributes: Attributes

            struct Attributes: Encodable {

                let token: String
            }
        }
    }

    private let api: API
    private let userDataProvider: UserDataProviderProtocol

    init(
        api: API,
        userDataProvider: UserDataProviderProtocol
    ) {

        self.api = api
        self.userDataProvider = userDataProvider
    }
}

// MARK: - Private methods

private extension FCMTokenUploader {

    func bodyData(with token: FCMTokenUploaderProtocol.Token) throws -> Data {
        let fcmTokenData: FCMToken = .init(
            data: .init(
                attributes: .init(
                    token: token
                )
            )
        )
        return try fcmTokenData.encode()
    }
}

// MARK: - FCMTokenUploaderProtocol

extension FCMTokenUploader: FCMTokenUploaderProtocol {

    func uploadToken(
        _ token: Token,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {

        let baseUrl = api.baseApiStack.apiConfiguration.urlString
        let accountId = userDataProvider.walletData.accountId
        let url = baseUrl/"firebase"/"notification"/"device"/accountId

        let data: Data
        do {
            data = try bodyData(with: token)
        } catch {
            completion(.failure(error))
            return
        }

        let requestMethod: RequestMethod = .post
        api.baseApiStack.requestSigner.sign(
            request: .init(
                baseUrlString: baseUrl,
                urlString: url,
                httpMethod: requestMethod
            ),
            sendDate: Date(),
            completion: { [weak self] (signedHeaders) in
                self?.api.network.responseDataEmpty(
                    url: url,
                    method: requestMethod,
                    headers: signedHeaders,
                    bodyData: data,
                    completion: { (result) in

                        switch result {

                        case .success:
                            completion(.success(()))

                        case .failure(let errors):
                            if errors.contains(status: "409") {
                                completion(.success(()))
                            } else {
                                completion(.failure(errors))
                            }
                        }
                    }
                )
            })
    }
}
