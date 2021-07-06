import Foundation
import TokenDSDK
import TokenDWallet

public class TransactionCreator {

    enum FetchNetworkInfoError: Swift.Error {
        case apiError(Swift.Error)
    }
    enum BuildTransactionError: Swift.Error {
        case failedToBuildTransaction(Swift.Error)
    }

    public typealias Operation = TokenDWallet.Operation.OperationBody

    // MARK: - Private properties

    private let networkInfoFetcher: NetworkInfoFetcher

    // MARK: -

    public init(
        networkInfoFetcher: NetworkInfoFetcher
    ) {

        self.networkInfoFetcher = networkInfoFetcher
    }
}

// MARK: - Private methods

private extension TransactionCreator {

    func fetchNetworkInfo(
        sourceAccountId: AccountID,
        operations: [Operation],
        salt: TokenDWallet.Salt?,
        sendDate: Date,
        completion: @escaping (CreateTransactionResult) -> Void
        ) {

        networkInfoFetcher.fetchNetworkInfo { [weak self] (result) in

            switch result {

            case .failure(let error):
                completion(.failure(FetchNetworkInfoError.apiError(error)))

            case .success(let networkInfo):
                self?.buildTransaction(
                    networkInfo: networkInfo,
                    sourceAccountId: sourceAccountId,
                    operations: operations,
                    salt: salt,
                    sendDate: sendDate,
                    completion: completion
                )
            }
        }
    }

    func buildTransaction(
        networkInfo: NetworkInfoModel,
        sourceAccountId: AccountID,
        operations: [Operation],
        salt: TokenDWallet.Salt?,
        sendDate: Date,
        completion: @escaping (CreateTransactionResult) -> Void
    ) {

        let transactionBuilder: TransactionBuilder = .init(
            networkParams: networkInfo.networkParams,
            sourceAccountId: sourceAccountId,
            params: networkInfo.getTxBuilderParams(
                salt: salt,
                sendDate: sendDate
            )
        )

        operations.forEach { (operation) in
            transactionBuilder.add(operationBody: operation)
        }

        do {
            completion(.success(try transactionBuilder.buildTransaction()))
        } catch (let error) {
            completion(.failure(error))
        }
    }
}

// MARK: - Public methods

public extension TransactionCreator {

    enum CreateTransactionResult {

        case success(TransactionModel)
        case failure(Swift.Error)
    }
    func createTransaction(
        sourceAccountId: AccountID,
        operations: [Operation],
        salt: TokenDWallet.Salt? = nil,
        sendDate: Date,
        completion: @escaping (CreateTransactionResult) -> Void
    ) {

        fetchNetworkInfo(
            sourceAccountId: sourceAccountId,
            operations: operations,
            salt: salt,
            sendDate: sendDate,
            completion: completion
        )
    }
}
