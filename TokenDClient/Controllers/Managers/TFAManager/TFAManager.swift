import Foundation
import TokenDSDK
import RxSwift
import RxCocoa

final class TFAManager {
    
    typealias HandleSecretCompletion = (_ continue: Bool) -> Void
    typealias HandleSecret = (_ secret: String, _ seed: String, _ completion: @escaping HandleSecretCompletion) -> Void
    
    // MARK: - Private properties

    private let tfaApi: TFAApi
    private let userDataProvider: UserDataProviderProtocol

    private var tfaStatus: BehaviorRelay<TFAStatus> = .init(value: .undetermined)
    
    private let handleSecret: HandleSecret?

    // MARK: -
    
    init(
        tfaApi: TFAApi,
        userDataProvider: UserDataProviderProtocol,
        handleSecret: @escaping HandleSecret
    ) {
        self.tfaApi = tfaApi
        self.userDataProvider = userDataProvider
        self.handleSecret = handleSecret
    }
}

private extension TFAManager {
    
    func deleteTOTPFactors(
        walletId: String,
        completion: @escaping (_ result: Result<Void, Swift.Error>) -> Void
    ) {
        self.tfaApi.getFactors(
            walletId: walletId,
            completion: { [weak self] (result: Swift.Result) in
                switch result {
                
                case .failure(let errors):
                    completion(.failure(errors))
                    
                case .success(let factors):
                    let totpFactors = factors.getTOTPFactors()
                    
                    do {
                        if let totpFactor = totpFactors.first {
                            self?.tfaApi.deleteFactor(
                                walletId: walletId,
                                factorId: try totpFactor.id.toInt(),
                                completion: { (deleteResult: Swift.Result) in
                                    switch deleteResult {
                                    
                                    case .failure(let error):
                                        completion(.failure(error))
                                        
                                    case .success:
                                        self?.deleteTOTPFactors(
                                            walletId: walletId,
                                            completion: completion
                                        )
                                    }
                                }
                            )
                        } else {
                            completion(.success(()))
                        }
                    } catch let error {
                        completion(.failure(error))
                    }
                }
            }
        )
    }
    
    func enableTOTPFactor(
        walletId: String,
        completion: @escaping (_ result: Result<Void, Swift.Error>) -> Void
    ) {
        
        let createFactor: (_ priority: Int) -> Void = { [weak self] (priority) in
            self?.tfaApi.createFactor(
                walletId: walletId,
                type: TFAFactorType.totp.rawValue,
                completion: { (result: Swift.Result) in
                    switch result {
                    
                    case .failure(let error):
                        self?.updateTFAStatus(
                            completion: {
                                completion(.failure(error))
                            }
                        )
                        
                    case .success(let response):
                        self?.handleSecret?(
                            response.attributes.secret,
                            response.attributes.seed,
                            { [weak self] (shouldContinue) in
                                
                                if shouldContinue {
                                    self?.updateTOTPFactor(
                                        walletId: walletId,
                                        factorId: response.id,
                                        priority: priority,
                                        completion: completion
                                    )
                                } else {
                                    self?.updateTFAStatus(
                                        completion: {
                                            completion(.success(()))
                                        }
                                    )
                                }
                            }
                        )
                    }
                }
            )
        }
        
        self.tfaApi.getFactors(
            walletId: walletId,
            completion: { (result: Swift.Result) in
                switch result {
                
                case .failure(let errors):
                    completion(.failure(errors))
                    
                case .success(let factors):
                    let priority = factors.getHighestPriority(factorType: nil) + 1
                    createFactor(priority)
                }
            }
        )
    }
    
    private func updateTOTPFactor(
        walletId: String,
        factorId: String,
        priority: Int,
        completion: @escaping (_ result: Result<Void, Swift.Error>) -> Void
        ) {
        
        do {
            self.tfaApi.updateFactor(
                walletId: walletId,
                factorId: try factorId.toInt(),
                priority: priority,
                completion: { [weak self] (result: Swift.Result) in
                    switch result {
                    
                    case .failure(let error):
                        completion(.failure(error))
                        
                    case .success:
                        self?.tfaStatus.accept(.loaded(enabled: true))
                        completion(.success(()))
                    }
                }
            )
        } catch let error {
            completion(.failure(error))
        }
    }
    
    func fetchTFAStatus() {
        
        switch self.tfaStatus.value {
            
        case .undetermined,
             .failed:
            updateTFAStatus(completion: nil)
            
        case .loading,
             .loaded:
            break
        }
    }
    
    func updateTFAStatus(
        completion: (() -> Void)?
    ) {
        
        self.tfaStatus.accept(.loading)
        
        let walletId = self.userDataProvider.walletId
        self.tfaApi.getFactors(
            walletId: walletId,
            completion: { [weak self] (result: Swift.Result) in
                switch result {
                
                case .failure(_):
                    self?.updateTFAStatus(completion: nil)
                    
                case .success(let factors):
                    let isEnabled = factors.isTOTPEnabled()
                    self?.tfaStatus.accept(.loaded(enabled: isEnabled))
                }
                
                completion?()
            }
        )
    }
}

extension TFAManager: TFAManagerProtocol {
    
    var status: TFAStatus {
        tfaStatus.value
    }
    
    func observeTfaStatus() -> Observable<TFAStatus> {
        fetchTFAStatus()
        return tfaStatus.asObservable()
    }
    
    func enableTFA(
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let walletId = self.userDataProvider.walletId
        
        self.deleteTOTPFactors(
            walletId: walletId,
            completion: { [weak self] (result) in
                switch result {
                
                case .failure(let error):
                    self?.updateTFAStatus(
                        completion: {
                            completion(.failure(error))
                        }
                    )
                    
                case .success:
                    self?.enableTOTPFactor(
                        walletId: walletId,
                        completion: { [weak self] (result) in
                            
                            switch result {
                            
                            case .success():
                                completion(.success(()))
                            case .failure(let error):
                                self?.updateTFAStatus(
                                    completion: {
                                        completion(.failure(error))
                                    }
                                )
                            }
                        }
                    )
                }
            }
        )
    }
    
    func disableTFA(
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let walletId = self.userDataProvider.walletId
        
        self.deleteTOTPFactors(
            walletId: walletId,
            completion: { [weak self] (result) in
                self?.updateTFAStatus(
                    completion: {
                        
                        switch result {
                        
                        case .failure(let error):
                            completion(.failure(error))
                            
                        case .success:
                            completion(.success(()))
                        }
                    }
                )
            }
        )
    }
}

private extension String {
    
    enum ToIntError: Swift.Error {
        case cannotCast
    }
    func toInt() throws -> Int {
        guard let id = Int(self)
        else {
            throw ToIntError.cannotCast
        }
        return id
    }
}
