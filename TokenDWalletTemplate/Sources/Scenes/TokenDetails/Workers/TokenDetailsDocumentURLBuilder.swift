import Foundation
import TokenDSDK

extension TokenDetailsScene {
    class DocumentURLBuilder: DocumentURLBuilderProtocol {
        
        private let apiConfiguration: APIConfigurationModel
        
        init(
            apiConfiguration: APIConfigurationModel
            ) {
            
            self.apiConfiguration = apiConfiguration
        }
        
        func getURLForTerms(_ terms: Asset.Details.Term) -> URL? {
            return URL(string: self.apiConfiguration.storageEndpoint + "/" + terms.key)
        }
    }
}
