import Foundation
import TokenDSDK

class AccountRoleFetcher {
    
    // MARK: - Private methods
    
    private let identitiesApi: IdentitiesApi
    private let accountsApi: AccountsApiV3
    
    // MARK: -
    
    init(
        identitiesApi: IdentitiesApi,
        accountsApi: AccountsApiV3
    ) {
        
        self.identitiesApi = identitiesApi
        self.accountsApi = accountsApi
    }
}

// MARK: - Private methods

private extension AccountRoleFetcher {
    
    func getIdentities(
        login: String,
        completion: @escaping (Result<RoleID, Error>) -> Void
    ) {
        
        self.identitiesApi.requestIdentities(
            filter: .login(login),
            completion: { [weak self] (result: Swift.Result<[IdentityResponse<EmptySpecificAttributes>], Swift.Error>) in
                
                switch result {
                
                case .failure(let error):
                    completion(.failure(error))
                    
                case .success(let identities):
                    guard let identity = identities.first
                    else {
                        completion(.failure(AccountRoleFetcherError.noIdentity))
                        return
                    }
                    
                    self?.getRole(
                        accountId: identity.attributes.address,
                        completion: completion
                    )
                }
            })
    }
    
    func getRole(
        accountId: String,
        completion: @escaping (Result<RoleID, Error>) -> Void
    ) {
        
        accountsApi.requestAccount(
            accountId: accountId,
            include: nil,
            pagination: nil,
            completion: { (result) in
                
                switch result {
                
                case .failure(let error):
                    completion(.failure(error))
                    
                case .success(let document):
                    guard let roleId = document.data?.role?.id
                    else {
                        completion(.failure(AccountRoleFetcherError.noRole))
                        return
                    }
                    
                    completion(.success(roleId))
                }
            })
    }
}

extension AccountRoleFetcher: AccountRoleFetcherProtocol {
    
    func fetchAccountRole(
        login: String,
        completion: @escaping (Result<RoleID, Error>) -> Void
    ) {
        
        getIdentities(
            login: login,
            completion: completion
        )
    }
}
