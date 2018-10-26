import Foundation

struct APIConfigurationModel: Decodable {
    let storageEndpoint: String
    let apiEndpoint: String
    let termsAddress: String?
    let webClient: String?
    let amountPrecision: Int
}
