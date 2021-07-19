import Foundation

public protocol NetworkInfoParserProtocol {
    
    func parseNetworkInfo(qrCodeValue: String) throws -> APIConfigurationModel 
}
