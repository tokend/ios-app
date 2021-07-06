import Foundation
import TokenDSDK
import TokenDWallet

class BalanceCreator {

    // MARK: - Private properties

    private let transactionCreator: TransactionCreator
    private let transactionSender: TransactionSender
    private let userDataProvider: UserDataProviderProtocol

    // MARK: -

    init(
        transactionCreator: TransactionCreator,
        transactionSender: TransactionSender,
        userDataProvider: UserDataProviderProtocol
    ) {

        self.transactionCreator = transactionCreator
        self.transactionSender = transactionSender
        self.userDataProvider = userDataProvider
    }
}

// MARK: - Private methods

private extension BalanceCreator {

    enum SendBalancesTransactionResult {
        case success(_ balancesIds: [String])
        case failure
    }
    func sendBalancesTransaction(
        model: TransactionModel,
        completion: @escaping (SendBalancesTransactionResult) -> Void
    ) {
        
        transactionSender.sendTransactionV3(
            model,
            completion: { (result) in
                
                switch result {
                
                case .succeeded(let resource):
                    
                    do {
                        
                        let ids = try resource
                            .transactionMeta()
                            .operations()
                            .createdChanges()
                            .balancesEntries()
                            .balanceIdentifiers()
                        completion(.success(ids))
                        
                    } catch {
                        
                        completion(.failure)
                    }
                    
                case .failed:
                    completion(.failure)
                }
            })
    }

    func createManageBalanceTransaction(
        for assets: [String],
        completion: @escaping (TransactionCreator.CreateTransactionResult) -> Void
    ) {

        let operations: [TokenDWallet.Operation.OperationBody] = assets.map { (asset) in
            return .manageBalance(
                .init(
                    action: .create,
                    destination: self.userDataProvider.accountId,
                    asset: asset,
                    ext: .emptyVersion
                )
            )
        }

        transactionCreator.createTransaction(
            sourceAccountId: userDataProvider.accountId,
            operations: operations,
            sendDate: Date(),
            completion: completion
        )
    }
}

// MARK: - Public methods

extension BalanceCreator {

    public enum CreateBalancesResult {
        case success(ids: [String])
        case failure
    }
    func createBalances(
        for assets: [String],
        completion: @escaping (CreateBalancesResult) -> Void
    ) {

        createManageBalanceTransaction(
            for: assets,
            completion: { [weak self] (result) in

                switch result {

                case .success(let model):
                    self?.sendBalancesTransaction(
                        model: model,
                        completion: { (result) in

                            switch result {

                            case .failure:
                                completion(.failure)

                            case .success(let ids):
                                completion(.success(ids: ids))
                            }
                    })

                case .failure:
                    completion(.failure)
                }
            }
        )
    }
}

// MARK: - Mappers

private extension Horizon.TransactionResource {

    func transactionMeta() throws -> TokenDWallet.TransactionMeta {

        return try TokenDWallet.TransactionMeta(xdrBase64: resultMetaXdr)
    }
}

private extension TokenDWallet.TransactionMeta {

    func operations() -> [TokenDWallet.OperationMeta] {

        switch self {

        case .emptyVersion(let operations):
            return operations
        }
    }
}

private extension Array where Element == TokenDWallet.OperationMeta {

    func createdChanges() -> [LedgerEntry] {

        flatMap { $0.createdChanges() }
    }
}

private extension TokenDWallet.OperationMeta {

    func createdChanges() -> [LedgerEntry] {

        changes
            .compactMap { (change) in

                switch change {

                case .created(let entry):
                    return entry

                case .updated,
                     .removed,
                     .state:
                    return nil
                }
        }
    }
}

private extension Array where Element == TokenDWallet.LedgerEntry {

    func balancesEntries() -> [TokenDWallet.BalanceEntry] {

        compactMap { $0.balanceEntry() }
    }
}

private extension TokenDWallet.LedgerEntry {

    func balanceEntry() -> TokenDWallet.BalanceEntry? {

        switch data {

        case .balance(let entry):
            return entry

        case .account,
             .signer,
             .fee,
             .asset,
             .referenceEntry,
             .statistics,
             .accountLimits,
             .assetPair,
             .offerEntry,
             .reviewableRequest,
             .externalSystemAccountId,
             .sale,
             .keyValue,
             .accountKyc,
             .externalSystemAccountIdPoolEntry,
             .limitsV2,
             .statisticsV2,
             .pendingStatistics,
             .contract,
             .atomicSwapAsk,
             .accountRole,
             .accountRule,
             .signerRule,
             .signerRole,
             .license,
             .stamp,
             .poll,
             .vote,
             .accountSpecificRule,
             .swap,
             .data:
            return nil
        }
    }
}

private extension Array where Element == TokenDWallet.BalanceEntry {

    func balanceIdentifiers() -> [String] {

        map { $0.balanceIdentifier() }
    }
}

private extension TokenDWallet.BalanceEntry {

    func balanceIdentifier() -> String {

        switch balanceID {

        case .keyTypeEd25519(let uint):
            return Base32Check.encode(version: .balanceIdEd25519, data: uint.wrapped)
        }
    }
}
