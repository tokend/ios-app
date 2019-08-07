import Foundation
import TokenDSDK
import TokenDWallet

extension UpdatePassword {
    
    class BaseSubmitWorker {
        
        // MARK: - Public properties
        
        let keyserverApi: KeyServerApi
        let keychainManager: KeychainManagerProtocol
        let userDataManager: UserDataManagerProtocol
        let networkInfoFetcher: NetworkInfoFetcher
        
        // MARK: -
        
        init(
            keyserverApi: KeyServerApi,
            keychainManager: KeychainManagerProtocol,
            userDataManager: UserDataManagerProtocol,
            networkInfoFetcher: NetworkInfoFetcher
            ) {
            
            self.keyserverApi = keyserverApi
            self.keychainManager = keychainManager
            self.userDataManager = userDataManager
            self.networkInfoFetcher = networkInfoFetcher
        }
        
        // MARK: - Public
        
        func getExpectedFields() -> [Model.Field] {
            return []
        }
        
        func fieldValueForType(fields: [Model.Field], fieldType: Model.FieldType) -> String? {
            let value = fields.first(where: { (field) in
                return field.type == fieldType
            })?.value
            
            return value
        }
    }
}
