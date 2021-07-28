import Foundation
import RxSwift
import RxCocoa
import TokenDSDK

class ActiveKYCRepo {
    
    typealias KYC = ActiveKYC

    // MARK: - Private properties

    private let accountRepo: AccountRepo
    private let blobsApi: BlobsApi

    private let latestChangeRoleRequestProvider: LatestChangeRoleRequestProvider
    private let accountTypeFetcher: AccountTypeFetcherProtocol
    private let activeKycBehaviorRelay: BehaviorRelay<KYC?> = .init(value: nil)

    private let disposeBag: DisposeBag = .init()

    // MARK: - Public properties

    public var activeKyc: KYC? {
        activeKycBehaviorRelay.value
    }

    // MARK: -

    init(
        accountRepo: AccountRepo,
        blobsApi: BlobsApi,
        latestChangeRoleRequestProvider: LatestChangeRoleRequestProvider,
        accountTypeFetcher: AccountTypeFetcherProtocol
    ) {

        self.accountRepo = accountRepo
        self.blobsApi = blobsApi
        self.accountTypeFetcher = accountTypeFetcher
        self.latestChangeRoleRequestProvider = latestChangeRoleRequestProvider

        observeAccountRepo()
    }
}

// MARK: - Private methods

private extension ActiveKYCRepo {

    func observeAccountRepo() {

        accountRepo
            .observeAccount()
            .subscribe(onNext: { [weak self] (account) in
                if let account = account,
                   let kyc = account.kycData {
                    
                    self?.accountTypeFetcher.fetchAccountType(
                        roleId: account.roleId,
                        completion: { [weak self] (result) in
                            
                            switch result {
                            
                            case .success(let accountType):
                                self?.requestKYCBlob(
                                    kyc.blobId,
                                    accountType: accountType,
                                    completion: { [weak self] (result) in
                                        
                                        switch result {
                                        
                                        case .failure:
                                            self?.activeKycBehaviorRelay.accept(nil)
                                            
                                        case .success(let form):
                                            self?.activeKycBehaviorRelay.accept(form.0)
                                        }
                                    })
                                
                            case .failure:
                                self?.activeKycBehaviorRelay.accept(nil)
                            }
                        }
                    )
                } else {
                    self?.activeKycBehaviorRelay.accept(nil)
                }
            })
            .disposed(by: disposeBag)
    }

    func requestKYCBlob(
        _ id: String,
        accountType: AccountType,
        completion: @escaping (Result<(KYC, String), Swift.Error>) -> Void
    ) {

        blobsApi.getBlob(
            blobId: id,
            completion: { (result) in
                
                switch result {

                case .failure(let error):
                    completion(.failure(error))

                case .success(let blob):
                    do {
                        let kyc = try blob.getBlobContent().kyc(
                            accountType: accountType
                        )
                        completion(.success((kyc, blob.id)))
                    } catch (let error) {
                        completion(.failure(error))
                    }
                }
            }
        )
    }
}

// MARK: - Public methods

extension ActiveKYCRepo {

    func observeActiveKYC() -> Observable<KYC?> {
        activeKycBehaviorRelay.asObservable()
    }

    enum LoadLatestChangeRoleRequestKYCError: Swift.Error {
        
        case noBlobId
    }
    func loadLatestChangeRoleRequestKYC(
        completion: @escaping (Result<(KYC, String), Swift.Error>) -> Void
    ) {
        
        latestChangeRoleRequestProvider
            .fetchLatest({ [weak self] (result) in
                
                switch result {
                
                case .failure(let error):
                    completion(.failure(error))
                    
                case .success(let request):
                    
                    guard let blobId = request.changeRoleRequest.creatorDetails["blobId"] as? String
                    else {
                        completion(.failure(LoadLatestChangeRoleRequestKYCError.noBlobId))
                        return
                    }
                    
                    self?.accountTypeFetcher.fetchAccountType(
                        roleId: "\(request.changeRoleRequest.accountRoleToSet)",
                        completion: { [weak self] (result) in
                            
                            switch result {
                            
                            case .success(let accountType):
                                self?.requestKYCBlob(
                                    blobId,
                                    accountType: accountType,
                                    completion: completion
                                )
                                
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        })
                }
            })
    }

    func requestActiveKYC(
        completion: ((Result<AccountRepo.Account.KYCData?, Swift.Error>) -> Void)?
    ) {

        accountRepo.updateAccount(
            completion: { (result) in

                switch result {

                case .failure(let error):
                    completion?(.failure(error))

                case .success(let account):
                    completion?(.success(account.kycData))
                }
        })
    }
}

// MARK: - Mapping

private enum BlobContentMappingError: Swift.Error {
    case wrongBlobContentType
}


enum BlobResponseBlobContentKYCError: Swift.Error {
    
    case unknownKYCFormType
}
private extension BlobResponse.BlobContent {

    func kyc(
        accountType: AccountType
    ) throws -> ActiveKYCRepo.KYC {

        switch self {

        case .assetDescription,
             .fundDocument,
             .fundOverview,
             .fundUpdate,
             .tokenMetrics,
             .unknown:
            throw BlobContentMappingError.wrongBlobContentType

        case .kycData(let data):
            
            switch accountType {
            
            case .general:
                return .form(try ActiveKYCRepo.GeneralKYCForm.decode(
                    from: data,
                    decoder: JSONCoders.snakeCaseDecoder
                ))
                
            case .corporate:
                return .form(try ActiveKYCRepo.CorporateKYCForm.decode(
                    from: data,
                    decoder: JSONCoders.snakeCaseDecoder
                ))
                
            case .unverified:
                return .missing
                
            case .blocked:
                throw BlobResponseBlobContentKYCError.unknownKYCFormType
            }
        }
    }
}

extension ActiveKYCRepo {
    
    enum ActiveKYC {
        
        case missing
        case form(AccountKYCForm)
    }

    struct GeneralKYCForm: Decodable, AccountKYCForm {
                
        // TODO: - Fill with fields
        
        var documents: [String : KYCDocument] {
            // TODO: - Implement
            return [:]
        }
        
        func update(
            with documents: [String : KYCDocument]
        ) -> ActiveKYCRepo.GeneralKYCForm {
            
            // TODO: - Implement
            
            return .init()
        }
    }
    
    struct CorporateKYCForm: Decodable, AccountKYCForm {
                
        // TODO: - Fill with fields
        
        var documents: [String : KYCDocument] {
            // TODO: - Implement
            return [:]
        }
        
        func update(
            with documents: [String : KYCDocument]
        ) -> ActiveKYCRepo.CorporateKYCForm {
            
            // TODO: - Implement
            
            return .init()
        }
    }
}
