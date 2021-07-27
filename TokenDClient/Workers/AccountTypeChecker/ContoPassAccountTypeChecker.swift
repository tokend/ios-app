import Foundation
import TokenDSDK

class ContoPassAccountTypeChecker {

    // MARK: - Private methods

    private let accountTypeFetcher: AccountTypeFetcherProtocol

    // MARK: -

    init(
        accountTypeFetcher: AccountTypeFetcherProtocol
    ) {

        self.accountTypeFetcher = accountTypeFetcher
    }
}

// MARK: - Private methods

private extension ContoPassAccountTypeChecker {
    
    func getAccountType(
        login: String,
        completion: @escaping (AccountTypeCheckerResult) -> Void
    ) {
        
        accountTypeFetcher.fetchAccountType(
            login: login,
            completion: { (result) in
                
                switch result {
                
                case .failure(let error):
                    
                    switch error {
                    
                    case AccountRoleFetcherError.noIdentity:
                        completion(.failure(.notInvited))
                        
                    case AccountTypeFetcherError.unsupportedAccountType:
                        completion(.failure(.unsupportedAccountType))
                        
                    default:
                        completion(.failure(.error(error)))
                    }
                    
                case .success(let type):
                    
                    completion(.success(type))
                }
            }
        )
    }
}

extension ContoPassAccountTypeChecker: AccountTypeCheckerProtocol {

    func checkAccountType(
        login: String,
        completion: @escaping (AccountTypeCheckerResult) -> Void
    ) {

        getAccountType(
            login: login,
            completion: completion
        )
    }
}
