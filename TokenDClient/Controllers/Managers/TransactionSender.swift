import Foundation
import TokenDWallet
import TokenDSDK
import RxCocoa
import RxSwift

public class TransactionSender {
    
    // MARK: - Private properties
    
    private let apiV3: TransactionsApiV3
    private let transactionSigner: TransactionSigner
    private let transactionActionRelay: PublishRelay<Void> = PublishRelay()
    
    // MARK: -
    
    public init(
        apiV3: TransactionsApiV3,
        transactionSigner: TransactionSigner
        ) {
        
        self.apiV3 = apiV3
        self.transactionSigner = transactionSigner
    }
    
    // MARK: - Public

    public enum SendTransactionV3Error: Swift.Error {
        case noData
    }
    public enum SendTransactionV3Result {

        case succeeded(Horizon.TransactionResource)
        case failed(Swift.Error)
    }
    public func sendTransactionV3(
        _ transaction: TransactionModel,
        completion: @escaping (SendTransactionV3Result) -> Void
    ) {

        transactionSigner.signTransaction(
            transaction,
            completion: { [weak self] (result) in

                switch result {

                case .failed(let error):
                    completion(.failed(error))

                case .succeeded(let transaction):
                    self?.apiV3.requestSubmitTransaction(
                        envelope: transaction.getEnvelope().toXdrBase64String(),
                        waitForIngest: true,
                        completion: { (result) in
                            switch result {

                            case .success(let resource):
                                guard let data = resource.data else {
                                    completion(.failed(SendTransactionV3Error.noData))
                                    return
                                }

                                completion(.succeeded(data))

                            case .failure(let error):
                                completion(.failed(error))
                            }
                        })
                }
            })
    }
    
    public func observeTransactionActions() -> Observable<Void> {
        return transactionActionRelay.asObservable()
    }
}
