import Foundation
import TokenDWallet
import TokenDSDK

public class TransactionSigner {

    // MARK: - Private properties

    private let keychainDataProvider: KeychainDataProviderProtocol

    // MARK: -

    public init(
        keychainDataProvider: KeychainDataProviderProtocol
        ) {

        self.keychainDataProvider = keychainDataProvider
    }

    public enum SignTransactionV3Result {

        case succeeded(TransactionModel)
        case failed(Swift.Error)
    }
    public func signTransaction(
        _ transaction: TransactionModel,
        completion: @escaping (SignTransactionV3Result) -> Void
    ) {

        do {
            try transaction.addSignature(signer: keychainDataProvider.getKeyData())

            completion(.succeeded(transaction))
        } catch (let error) {
            completion(.failed(error))
        }
    }
}
