import Foundation

public protocol NetworkInfoWorkerProtocol {
    
    func handleNetworkInfo(qrCodeValue: String) throws -> APIConfigurationModel 
}
