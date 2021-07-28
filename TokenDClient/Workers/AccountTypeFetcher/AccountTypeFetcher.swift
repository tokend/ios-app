import Foundation
import TokenDSDK

class AccountTypeFetcher {
    
    // MARK: - Private methods

    private let accountRoleFetcher: AccountRoleFetcherProtocol
    private let keyValuesApi: KeyValuesApiV3

    // MARK: -

    init(
        accountRoleFetcher: AccountRoleFetcherProtocol,
        keyValuesApi: KeyValuesApiV3
    ) {

        self.accountRoleFetcher = accountRoleFetcher
        self.keyValuesApi = keyValuesApi
    }
}

// MARK: - Private methods

private extension AccountTypeFetcher {
    
    func getRole(
        login: String,
        completion: @escaping (Result<AccountType, Swift.Error>) -> Void
    ) {

        accountRoleFetcher.fetchAccountRole(
            login: login,
            completion: { [weak self] (result) in
                
                switch result {

                case .failure(let error):
                    completion(.failure(error))

                case .success(let roleId):
                    self?.getAccountType(
                        roleId: roleId,
                        completion: completion
                    )
                }
            }
        )
    }
    
    func requestKeyValue(
        key: String,
        completion: @escaping (String?) -> Void
    ) {
        
        keyValuesApi.requestKeyValue(
            key: key,
            completion: { (result) in

                switch result {

                case .failure:
                    completion(nil)

                case .success(let document):
                    if let u32 = document.data?.value?.u32 {
                        completion("\(u32)")
                    } else {
                        completion(nil)
                    }
                }
        })
    }

    func getAccountType(
        roleId: String,
        completion: @escaping (Result<AccountType, Swift.Error>) -> Void
    ) {
        
        var userRoleIdDictionary: [AccountType: String?] = [:]

        let group: DispatchGroup = .init()

        group.enter()
        
        for type in AccountType.allCases {
            
            group.enter()
            requestKeyValue(
                key: type.userKey,
                completion: { (value) in
                    userRoleIdDictionary[type] = value
                    group.leave()
                }
            )
        }

        group.notify(
            queue: .main,
            execute: {
                
                for type in userRoleIdDictionary.keys {
                    if userRoleIdDictionary[type] == roleId {
                        completion(.success(type))
                        return
                    }
                }
                
                completion(.failure(AccountTypeFetcherError.unsupportedAccountType))
        })
        
        group.leave()
    }
}

extension AccountTypeFetcher: AccountTypeFetcherProtocol {
    
    func fetchAccountType(
        login: String,
        completion: @escaping (Result<AccountType, Swift.Error>) -> Void
    ) {
        
        getRole(
            login: login,
            completion: completion
        )
    }
    
    func fetchAccountType(
        roleId: String,
        completion: @escaping (Result<AccountType, Error>) -> Void
    ) {
        
        getAccountType(
            roleId: roleId,
            completion: completion
        )
    }
}
