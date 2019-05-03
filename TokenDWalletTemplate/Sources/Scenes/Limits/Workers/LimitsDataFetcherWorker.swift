import Foundation
import TokenDSDK

extension Limits {
    
    public class LimitsDataFetcherWorker {
        
        // MARK: - Private properties
        
        private let accountsApi: AccountsApiV3
        
        // MARK: -
        
        public init(accountsApi: AccountsApiV3) {
            self.accountsApi = accountsApi
        }
        
        // MARK: - Private
        
        private func mapLimitResources(
            _ resources: [LimitResource]?
            ) -> [Model.Asset: [Model.LimitsModel]] {
            
            return [:]
        }
    }
}

extension Limits.LimitsDataFetcherWorker: Limits.LimitsDataFetcher {
    
    public func fetchLimits(accountId: String, completion: @escaping (_ result: Result) -> Void) {
        self.accountsApi.requestAccount(
            accountId: accountId,
            include: ["limits"],
            pagination: nil,
            completion: { [weak self] (result) in
                switch result {
                    
                case .failure(let error):
                    completion(.failure(error))
                    
                case .success(let document):
                    let limits = self?.mapLimitResources(document.data?.limits) ?? [:]
                    completion(.success(limits: limits))
                }
        })
    }
}
