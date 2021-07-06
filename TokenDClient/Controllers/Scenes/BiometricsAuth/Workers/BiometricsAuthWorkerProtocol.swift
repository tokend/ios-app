import Foundation

enum BiometricsAuthWorkerResult {
    case failure
    case success(login: String)
    case userCancel
    case userFallback
}

protocol BiometricsAuthWorkerProtocol {
    
    func performAuth(
        completion: @escaping ((_ result: BiometricsAuthWorkerResult) -> Void)
    )
}

extension BiometricsAuth {
    
    typealias AuthWorkerProtocol = BiometricsAuthWorkerProtocol
}
