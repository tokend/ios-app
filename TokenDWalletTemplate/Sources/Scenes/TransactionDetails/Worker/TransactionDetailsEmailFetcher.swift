import Foundation
import TokenDWallet
import TokenDSDK

enum TransactionDetailsEmailFetcherResult {
    case succeeded(_ email: String)
    case failed
}
protocol TransactionDetailsEmailFetcherProtocol {
    func fetchEmail(
        accountId: String,
        completion: @escaping (_ result: TransactionDetailsEmailFetcherResult) -> Void
    )
}

extension TransactionDetails {
    typealias EmailFetcherProtocol = TransactionDetailsEmailFetcherProtocol
    
    class EmailFetcher: EmailFetcherProtocol {
        
        // MARK: - Private properties
        
        private let generalApi: GeneralApi
        
        // MARK: -
        
        init(generalApi: GeneralApi) {
            self.generalApi = generalApi
        }
        
        // MARK: - EmailFetcherProtocol
        
        func fetchEmail(
            accountId: String,
            completion: @escaping (_ result: TransactionDetailsEmailFetcherResult) -> Void
            ) {
            
            self.generalApi.requestIdentities(
                filter: .accountId(accountId),
                completion: { (result) in
                    switch result {
                        
                    case .failed:
                        completion(.failed)
                        
                    case .succeeded(let response):
                        guard let identity = response.first(where: { (identity) -> Bool in
                            return identity.attributes.address == accountId
                        }) else {
                            completion(.failed)
                            return
                        }
                        completion(.succeeded(identity.attributes.email))
                    }
            })
        }
    }
}
