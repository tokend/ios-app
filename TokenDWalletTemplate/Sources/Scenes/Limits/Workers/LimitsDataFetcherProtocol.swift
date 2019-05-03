import Foundation

public enum LimitsDataFetcherResult {
    case failure(Swift.Error)
    case success(limits: [Limits.Model.Asset: [Limits.Model.LimitsModel]])
}

public protocol LimitsDataFetcherProtocol {
    
    typealias Result = LimitsDataFetcherResult
    
    func fetchLimits(
        accountId: String,
        completion: @escaping (_ result: Result) -> Void
    )
}

extension Limits {
    
    public typealias LimitsDataFetcher = LimitsDataFetcherProtocol
}
