import Foundation

class NetworkInfoParser {
    
    // MARK: - Private properties
    
    private let decoder: JSONDecoder = .init()
}

private extension NetworkInfoParser {
    struct NetworkInfo: Decodable {
        let api: String
        let storage: String
        let kyc: String
        let terms: String?
        let web: String?
        let download: String?
    }
    
    func decodeQrCodeValue(value: String) throws -> APIConfigurationModel {
        
        let data = Data(value.utf8)
        
        let model = try decoder.decode(
            NetworkInfo.self,
            from: data
        )
        
        let apiConfigurationModel: APIConfigurationModel = .init(
            storageEndpoint: model.storage,
            apiEndpoint: model.api,
            termsAddress: model.terms,
            webClient: model.web,
            downloadUrl: model.download
        )
        
        return apiConfigurationModel
    }
}

extension NetworkInfoParser: NetworkInfoParserProtocol {
    func parseNetworkInfo(qrCodeValue: String) throws -> APIConfigurationModel {
        
        return try decodeQrCodeValue(value: qrCodeValue)
    }
}
