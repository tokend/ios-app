import Foundation

public struct APIConfigurationModel: Decodable {
    let storageEndpoint: String
    let apiEndpoint: String
    let termsAddress: String?
    let webClient: String?
    let downloadUrl: String?
    let verificationUrl: String
}
