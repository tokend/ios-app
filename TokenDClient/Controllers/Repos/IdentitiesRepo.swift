import Foundation
import RxSwift
import RxCocoa
import TokenDSDK

public class IdentitiesRepo {
    
    public typealias AccountId = String
    private typealias IdentitiesDictionary = [AccountId: IdentityState]
    
    // MARK: - Private properties
    
    private let identitiesApi: TokenDSDK.IdentitiesApi
    
    private let identitiesBehaviorRelay: BehaviorRelay<IdentitiesDictionary> = .init(value: [:])

    private let internalQueue: DispatchQueue = .init(label: "\(NSStringFromClass(IdentitiesRepo.self))".queueLabel, qos: .userInitiated)
    
    // MARK: - Public properties
    
    public var identitiesValue: [AccountId: Identity] {
        identitiesBehaviorRelay.value.mapToIdentities()
    }
    
    // MARK: -
    
    init(
        identitiesApi: TokenDSDK.IdentitiesApi
    ) {
        self.identitiesApi = identitiesApi
    }
}

// MARK: - Private methods

private extension IdentitiesRepo {
    
    enum IdentityState {
        case loading
        case loaded(Identity)
        case noIdentity
    }

    func loadIdentity(
        for filter: IdentitiesApi.RequestIdentitiesFilter,
        completion: @escaping (Result<Identity?, Swift.Error>) -> Void
    ) {
        
        self.identitiesApi.requestIdentities(
            filter: filter,
            completion: { (result: Swift.Result<[IdentityResponse<EmptySpecificAttributes>], Swift.Error>) in
                
                switch result {
                    
                case .failure(let error):
                    completion(.failure(error))
                    
                case .success(identities: let identities):
                    completion(.success(identities.first?.mapToIdentity()))
                }
            }
        )
    }
    
    func updateValue(
        for accountId: AccountId,
        value: IdentityState
    ) {
        
        var identities = identitiesBehaviorRelay.value
        identities[accountId] = value
        identitiesBehaviorRelay.accept(identities)
    }
    
    func removeValue(
        for accountId: AccountId
    ) {
        
        var identities = identitiesBehaviorRelay.value
        identities[accountId] = nil
        identitiesBehaviorRelay.accept(identities)
    }
}

// MARK: - Public methods

extension IdentitiesRepo {
    
    func observeIdentities() -> Observable<[AccountId: Identity]> {
        identitiesBehaviorRelay
            .asObservable()
            .map { (dictionary) in
                dictionary.mapToIdentities()
        }
    }
    
    func requestIdentity(
        withAccountId identifier: String,
        completion: ((Result<Identity?, Swift.Error>) -> Void)? = nil
    ) {

        internalQueue.async { [weak self] in
            switch self?.identitiesBehaviorRelay.value[identifier] {

            case .loaded(let identity):
                completion?(.success(identity))
                return

            case .noIdentity:
                completion?(.success(nil))
                return

            case .loading:
                // TODO: - Handle
                return

            case .none:
                break
            }

            self?.updateValue(for: identifier, value: .loading)
            self?.loadIdentity(
                for: .accountId(identifier),
                completion: { [weak self] (result) in

                    self?.internalQueue.async { [weak self] in
                        switch result {

                        case .success(let identity):
                            if let identity = identity {
                                self?.updateValue(for: identity.accountId, value: .loaded(identity))
                            } else {
                                self?.updateValue(for: identifier, value: .noIdentity)
                            }

                        case .failure:
                            self?.removeValue(for: identifier)
                        }

                        completion?(result)
                    }
            })
        }
    }
    
    func requestIdentity(
        withPhoneNumber identifier: String,
        completion: ((Result<Identity?, Swift.Error>) -> Void)? = nil
    ) {

        internalQueue.async { [weak self] in
            if let identity = self?.identitiesValue.first(where: {
                $0.value.phoneNumber == identifier
            }) {
                completion?(.success(identity.value))
                return
            }

            self?.updateValue(for: identifier, value: .loading)
            self?.loadIdentity(
                for: .login(identifier),
                completion: { [weak self] (result) in

                    self?.internalQueue.async { [weak self] in
                        switch result {

                        case .success(let identity):
                            if let identity = identity {
                                self?.updateValue(for: identity.accountId, value: .loaded(identity))
                            }

                        case .failure:
                            break
                        }

                        completion?(result)
                    }
            })
        }
    }
    
    func requestIdentity(
        withEmail identifier: String,
        completion: ((Result<Identity?, Swift.Error>) -> Void)? = nil
    ) {

        internalQueue.async { [weak self] in
            if let identity = self?.identitiesValue.first(where: {
                $0.value.email == identifier
            }) {
                completion?(.success(identity.value))
                return
            }

            self?.updateValue(for: identifier, value: .loading)
            self?.loadIdentity(
                for: .login(identifier),
                completion: { [weak self] (result) in

                    self?.internalQueue.async { [weak self] in
                        switch result {

                        case .success(let identity):
                            if let identity = identity {
                                self?.updateValue(for: identity.accountId, value: .loaded(identity))
                            }

                        case .failure:
                            break
                        }

                        completion?(result)
                    }
            })
        }
    }
    
    public enum AddIdentityResult {
        case success(Identity)
        case failure(Error)
    }
    
    func addIdentity(
        with phoneNumber: String,
        completion: @escaping ((AddIdentityResult) -> Void)
    ) {

        internalQueue.async { [weak self] in
            // TODO: - Update value
            
            self?.identitiesApi.addIdentity(
                withPhoneNumber: phoneNumber,
                completion: { [weak self] (result: Swift.Result<IdentityResponse<EmptySpecificAttributes>, Swift.Error>) in
                    
                    self?.internalQueue.async { [weak self] in
                        switch result {

                        case .success(let identity):

                            let addedIdentity = identity.mapToIdentity()
                            self?.updateValue(for: addedIdentity.accountId, value: .loaded(addedIdentity))
                            completion(.success(addedIdentity))

                        case .failure(let error):

                            // TODO: - Remove value
                            completion(.failure(error))
                        }
                    }
                }
            )
        }
    }
}

// MARK: - LoadingStatus -

extension IdentitiesRepo {
    
    enum LoadingStatus {
        case loading
        case loaded
    }
}

// MARK: - Identity -

extension IdentitiesRepo {
    
    public struct Identity: Hashable {
        
        let accountId: String
        let email: String
        let phoneNumber: String
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(accountId)
        }
        
        public static func == (lhs: Identity, rhs: Identity) -> Bool {
            return lhs.phoneNumber == rhs.phoneNumber
        }
    }
}

extension IdentityResponse {

    func mapToIdentity() -> IdentitiesRepo.Identity {
        
        var number: String
        
        if let phoneNumber = self.attributes.phoneNumber {
            number = phoneNumber
        } else {
            number = self.attributes.email
        }
        
        let identity: IdentitiesRepo.Identity = .init(
            accountId: attributes.address,
            email: self.attributes.email,
            phoneNumber: number
        )
        
        return identity
    }
}

private extension Dictionary where Key == IdentitiesRepo.AccountId, Value == IdentitiesRepo.IdentityState {

    func mapToIdentities() -> [IdentitiesRepo.AccountId: IdentitiesRepo.Identity] {
        compactMapValues { (state) in
            switch state {

            case .loaded(let identity):
                return identity

            case .loading,
                 .noIdentity:
                return nil
            }
        }
    }
}
