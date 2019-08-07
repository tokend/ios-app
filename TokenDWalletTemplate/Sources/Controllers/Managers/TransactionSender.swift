import Foundation
import TokenDWallet
import TokenDSDK

class TransactionSender {
    
    private let api: TransactionsApi
    private let keychainDataProvider: KeychainDataProviderProtocol
    
    init(
        api: TransactionsApi,
        keychainDataProvider: KeychainDataProviderProtocol
        ) {
        
        self.api = api
        self.keychainDataProvider = keychainDataProvider
    }
    
    enum SendTransactionResult {
        case succeeded
        case failed(Swift.Error)
    }
    public func sendTransaction(
        _ transaction: TransactionModel,
        walletId: String,
        completion: @escaping (SendTransactionResult) -> Void
        ) throws {
        
        try transaction.addSignature(signer: self.keychainDataProvider.getKeyData())
        
        self.api.sendTransaction(
            envelope: transaction.getEnvelope().toXdrBase64String()
        ) { (result) in
            switch result {
                
            case .success:
                completion(.succeeded)
                
            case .failure(let error):
                completion(.failed(error))
            }
        }
    }
}
