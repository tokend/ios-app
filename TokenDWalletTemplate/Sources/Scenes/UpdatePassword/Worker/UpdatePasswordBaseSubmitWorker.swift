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
        let updateRequestBuilder: UpdatePasswordRequestBuilderProtocol
        
        // MARK: -
        
        init(
            keyserverApi: KeyServerApi,
            keychainManager: KeychainManagerProtocol,
            userDataManager: UserDataManagerProtocol,
            networkInfoFetcher: NetworkInfoFetcher,
            updateRequestBuilder: UpdatePasswordRequestBuilderProtocol
            ) {
            
            self.keyserverApi = keyserverApi
            self.keychainManager = keychainManager
            self.userDataManager = userDataManager
            self.networkInfoFetcher = networkInfoFetcher
            self.updateRequestBuilder = updateRequestBuilder
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
