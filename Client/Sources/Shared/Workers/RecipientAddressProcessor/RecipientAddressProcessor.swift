import Foundation
import TokenDSDK
import TokenDWallet

class RecipientAddressProcessor {
    
    typealias Completion = (Result<RecipientAddress, Swift.Error>) -> Void
    
    enum RecipientAddressProcessorError: Swift.Error {
        case noIdentity
        case ownAccountId
    }
    
    // MARK: - Private properties
    
    private let identitiesRepo: IdentitiesRepo
    private let originalAccountId: String
    
    // MARK: -
    
    init(
        identitiesRepo: IdentitiesRepo,
        originalAccountId: String
    ) {
        self.identitiesRepo = identitiesRepo
        self.originalAccountId = originalAccountId
    }
}

// MARK: - Private methods

private extension RecipientAddressProcessor {
    
    func fetchAccountId(
        with email: String,
        completion: @escaping Completion
    ) {
        
        identitiesRepo.requestIdentity(
            withEmail: email,
            completion: { [weak self] (result) in
                                    
                    switch result {
                    
                    case .success(let identity):
                        guard let identity = identity
                        else {
                            completion(.failure(RecipientAddressProcessorError.noIdentity))
                            return
                        }
                        
                        self?.checkAccountId(
                            accountId: identity.accountId,
                            email: identity.email,
                            completion: completion
                        )
                        
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
        )
    }
    
    /// Checks if user is trying to send asset to himself
    func checkAccountId(
        accountId: String,
        email: String?,
        completion: @escaping Completion
    ) {
        if accountId != self.originalAccountId {
            let recipientAddress: RecipientAddress = .init(
                accountId: accountId,
                email: email
            )
            completion(.success(recipientAddress))
        } else {
            completion(.failure(RecipientAddressProcessorError.ownAccountId))
        }
    }
}

extension RecipientAddressProcessor: RecipientAddressProcessorProtocol {
    
    func processRecipientAddress(
        with value: String,
        completion: @escaping Completion
    ) {
                
        do {
            _ = try Base32Check.decodeCheck(
                expectedVersion: .accountIdEd25519,
                encoded: value
            )
            
            self.checkAccountId(
                accountId: value,
                email: nil,
                completion: completion
            )
        } catch {
            self.fetchAccountId(with: value.lowercased(), completion: completion)
        }
    }
}
