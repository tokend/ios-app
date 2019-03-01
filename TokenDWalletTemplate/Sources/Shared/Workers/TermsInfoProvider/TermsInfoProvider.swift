import Foundation

struct TermsInfoProvider {
    
    // MARK: - Public properties
    
    let apiConfigurationModel: APIConfigurationModel
    
    // MARK: -
    
    init(apiConfigurationModel: APIConfigurationModel) {
        self.apiConfigurationModel = apiConfigurationModel
    }
    
    // MARK: - Public
    
    func getTermsUrl() -> URL? {
        var termsUrl: URL?
        if var termsAddress = self.apiConfigurationModel.termsAddress {
            if !(termsAddress.hasPrefix("http://") || termsAddress.hasPrefix("https://")) {
                termsAddress = "https://\(termsAddress)"
            }
            termsUrl = URL(string: termsAddress)
        }
        
        return termsUrl
    }
}
