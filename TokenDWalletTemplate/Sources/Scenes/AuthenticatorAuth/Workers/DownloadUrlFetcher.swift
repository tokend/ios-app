import Foundation

protocol DownloadUrlFetcherProtocol {
    func fetchUrl() -> URL?
}

extension AuthenticatorAuth {
    
    class DownloadUrlFethcer {
        
        // MARK: - Private properties
        
        private let apiConfiguration: APIConfigurationModel
        
        // MARK: -
        
        init(apiConfiguration: APIConfigurationModel) {
            self.apiConfiguration = apiConfiguration
        }
    }
}

extension AuthenticatorAuth.DownloadUrlFethcer: DownloadUrlFetcherProtocol {
    func fetchUrl() -> URL? {
        guard let urLString = self.apiConfiguration.downloadUrl else {
            return nil
        }
        return URL(string: urLString)
    }
}
