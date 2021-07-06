import Foundation
import TokenDSDK
import TokenDWallet

class LatestKYCChecker {

    // MARK: - Private properties

    private let latestChangeRoleRequestProvider: LatestChangeRoleRequestProvider

    // MARK: -

    init(
        latestChangeRoleRequestProvider: LatestChangeRoleRequestProvider
        ) {

        self.latestChangeRoleRequestProvider = latestChangeRoleRequestProvider
    }
}

// MARK: - AccountKYCCheckerProtocol

extension LatestKYCChecker: AccountKYCCheckerProtocol {

    enum CheckKYCError: Swift.Error {

        case noAccount
    }
    func checkKYC(
        _ completion: @escaping (AccountKYCCheckerResult) -> Void
    ) {
        
        latestChangeRoleRequestProvider.fetchLatest(
            { (result) in
                
                switch result {
                
                case .failure(let error):
                    
                    switch error {
                    
                    case LatestChangeRoleRequestProvider.FetchLastChangeRoleRequestError.noChangeRoleRequests:
                        completion(.noKyc)
                        
                    default:
                        completion(.error(error))
                    }
                    
                case .success(let request):
                    
                    completion(.success(request.reviewableRequest.stateValue))
                }
            }
        )
    }
}
