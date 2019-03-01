import Foundation

protocol AuthRequestBuilderProtocol {
    func build(publicKey: String) -> URL?
}

extension AuthenticatorAuth {
    
    class AuthRequestBuilder {
        
        // MARK: - Private properties
        
        private let apiConfiguration: APIConfigurationModel
        
        // MARK: -
        
        init(apiConfiguration: APIConfigurationModel) {
            self.apiConfiguration = apiConfiguration
        }
    }
}

extension AuthenticatorAuth.AuthRequestBuilder: AuthRequestBuilderProtocol {
    
    func build(publicKey: String) -> URL? {
        let api = self.apiConfiguration.apiEndpoint
        let app = "TokenD+iOS+mobile+client"
        let scope = "2131"
        let expiresAt = "231435"
        let redirectUrl = "tokendwallet://result?success=<success>&error=<error>"
        
        guard let base64RedirectUrl = redirectUrl.data(using: .utf8)?.base64EncodedString(),
        var urlComponents = URLComponents(string: "tokend://auth") else {
            return nil
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "api", value: api),
            URLQueryItem(name: "app", value: app),
            URLQueryItem(name: "pubkey", value: publicKey),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "expires_at", value: expiresAt),
            URLQueryItem(name: "redirect_url", value: base64RedirectUrl)
        ]
        
        return urlComponents.url
    }
}
