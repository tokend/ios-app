import Foundation
import RxSwift
import RxCocoa
import TokenDSDK

class ActiveKYCRepo {

    // MARK: - Private properties

    private let accountRepo: AccountRepo
    private let blobsApi: BlobsApi

    private let latestChangeRoleRequestProvider: LatestChangeRoleRequestProvider
    private let activeKycBehaviorRelay: BehaviorRelay<KYCForm?> = .init(value: nil)

    private let disposeBag: DisposeBag = .init()

    // MARK: - Public properties

    public var activeKyc: KYCForm? {
        activeKycBehaviorRelay.value
    }

    // MARK: -

    init(
        accountRepo: AccountRepo,
        blobsApi: BlobsApi,
        latestChangeRoleRequestProvider: LatestChangeRoleRequestProvider
    ) {

        self.accountRepo = accountRepo
        self.blobsApi = blobsApi
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
                if let kyc = account?.kycData {
                    self?.requestKYCBlob(
                        kyc.blobId,
                        completion: { [weak self] (result) in

                            switch result {

                            case .failure:
                                self?.activeKycBehaviorRelay.accept(nil)

                            case .success(let form):
                                self?.activeKycBehaviorRelay.accept(form.0)
                            }
                    })
                } else {
                    self?.activeKycBehaviorRelay.accept(nil)
                }
            })
            .disposed(by: disposeBag)
    }

    func requestKYCBlob(
        _ id: String,
        completion: @escaping (Result<(KYCForm, String), Swift.Error>) -> Void
    ) {

        blobsApi.getBlob(
            blobId: id,
            completion: { (result) in
                
                switch result {

                case .failure(let error):
                    completion(.failure(error))

                case .success(let blob):
                    do {
                        let kyc = try blob.getBlobContent().kyc()
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

    func observeActiveKYC() -> Observable<KYCForm?> {
        activeKycBehaviorRelay.asObservable()
    }

    func loadLatestChangeRoleRequestKYC(
        completion: @escaping (Result<(KYCForm, String), Swift.Error>) -> Void
    ) {

        latestChangeRoleRequestProvider
            .fetchLatest({ [weak self] (result) in

                switch result {

                case .failure(let error):
                    completion(.failure(error))

                case .success(let request):

                    guard let blobId = request.changeRoleRequest.creatorDetails["blobId"] as? String
                        else {
                            return
                    }

                    self?.requestKYCBlob(
                        blobId,
                        completion: completion
                    )
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

private extension BlobResponse.BlobContent {

    func kyc(
    ) throws -> ActiveKYCRepo.KYCForm {

        switch self {

        case .assetDescription,
             .fundDocument,
             .fundOverview,
             .fundUpdate,
             .tokenMetrics,
             .unknown:
            throw BlobContentMappingError.wrongBlobContentType

        case .kycData(let data):
            return try .decode(from: data, decoder: JSONCoders.snakeCaseDecoder)
        }
    }
}

extension ActiveKYCRepo {

    struct KYCForm: Decodable, AccountKYCForm {
                
        // TODO: - Fill with fields
        
        var documents: [String : KYCDocument] {
            // TODO: - Implement
            return [:]
        }
        
        func update(
            with documents: [String : KYCDocument]
        ) -> ActiveKYCRepo.KYCForm {
            
            // TODO: - Implement
            
            return .init()
        }
    }
}
