import Foundation
import TokenDSDK
import TokenDWallet

class ChangeRoleRequestSender {
    
    enum BuildChangeRoleRequestError: Swift.Error {
        case failedToGetAccountID
        case failedToEncodeCreatorDetails(Swift.Error)
        case failedToFormCreatorDetailsJSON
    }
    enum SendTransactionError: Swift.Error {
        case failedToSendTransaction(Swift.Error)
    }
    
    // MARK: - Private properties
    
    private let transactionCreator: TransactionCreator
    private let transactionSender: TransactionSender
    private let originalAccountId: String
    
    // MARK: -
    
    init(
        transactionCreator: TransactionCreator,
        transactionSender: TransactionSender,
        originalAccountId: String
        ) {

        self.transactionCreator = transactionCreator
        self.transactionSender = transactionSender
        self.originalAccountId = originalAccountId
    }
}

// MARK: - Private methods

private extension ChangeRoleRequestSender {
    
    func buildChangeRoleRequest(
        blobId: String,
        roleId: UInt64,
        requestId: UInt64,
        completion: @escaping(Result<Void, Swift.Error>) -> Void
        ) {

        guard let destinationAccountID = AccountID(
            base32EncodedString: originalAccountId,
            expectedVersion: .accountIdEd25519
            ) else {
                completion(.failure(BuildChangeRoleRequestError.failedToGetAccountID))
                return
        }

        struct CreatorDetails: Encodable {

            let blobId: String
        }

        let creatorDetails: CreatorDetails = .init(
            blobId: blobId
        )

        do {
            let creatorDetailsJSONData = try snakeCaseEncoder.encode(creatorDetails)
            guard let creatorDetailsJSONString = String(data: creatorDetailsJSONData, encoding: .utf8)
                else {
                    completion(.failure(BuildChangeRoleRequestError.failedToFormCreatorDetailsJSON))
                    return
            }

            let changeOpReviewableRequest: CreateChangeRoleRequestOp = .init(
                requestID: requestId,
                destinationAccount: destinationAccountID,
                accountRoleToSet: roleId,
                creatorDetails: creatorDetailsJSONString,
                allTasks: nil,
                ext: .emptyVersion
            )

            buildTransaction(
                with: changeOpReviewableRequest,
                sourceAccountID: destinationAccountID,
                completion: completion
            )
        } catch (let error) {
            completion(.failure(BuildChangeRoleRequestError.failedToEncodeCreatorDetails(error)))
        }
    }

    func buildTransaction(
        with changeRoleRequest: CreateChangeRoleRequestOp,
        sourceAccountID: AccountID,
        completion: @escaping(Result<Void, Swift.Error>) -> Void
    ) {

        transactionCreator.createTransaction(
            sourceAccountId: sourceAccountID,
            operations: [
                .createChangeRoleRequest(changeRoleRequest)
            ],
            sendDate: Date(),
            completion: { [weak self] (result) in

                switch result {

                case .success(let transaction):
                    self?.sendTransaction(
                        transaction: transaction,
                        completion: completion
                    )

                case .failure(let error):
                    completion(.failure(error))
                }
        })
    }

    func sendTransaction(
        transaction: TransactionModel,
        completion: @escaping(Result<Void, Swift.Error>) -> Void
    ) {

        transactionSender.sendTransactionV3(
            transaction,
            completion: { (result) in

                switch result {

                case .failed(let error):
                    completion(.failure(SendTransactionError.failedToSendTransaction(error)))

                case .succeeded:
                    completion(.success(()))
                }
        })
    }
}

extension ChangeRoleRequestSender: ChangeRoleRequestSenderProtocol {
    
    func sendChangeRoleRequest(
        blobId: String,
        roleId: UInt64,
        requestId: UInt64,
        completion: @escaping (Result<Void, Swift.Error>) -> Void
    ) {
        
        buildChangeRoleRequest(
            blobId: blobId,
            roleId: roleId,
            requestId: requestId,
            completion: completion
        )
    }
}

private let snakeCaseEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    return encoder
}()
