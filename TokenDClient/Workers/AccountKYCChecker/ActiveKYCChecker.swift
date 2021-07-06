import Foundation
import TokenDSDK
import TokenDWallet

class ActiveKYCChecker {

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

extension ActiveKYCChecker: AccountKYCCheckerProtocol {

    enum CheckKYCError: Swift.Error {

        case noAccount
    }
    func checkKYC(
        _ completion: @escaping (AccountKYCCheckerResult) -> Void
    ) {
        
        latestChangeRoleRequestProvider.fetchLatest(
            state: .approved,
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
