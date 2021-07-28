import Foundation
import RxSwift
import RxCocoa
import TokenDSDK

/// Uses `integrations` API and should be used only if needed.
class KYCRepo {

    public typealias AccountId = String
    private typealias KYCUsersDictionary = [AccountId: KYCUserState]

    enum LoadUserResult {
        case failure(Error)
        case success(KYCUser)
    }

    // MARK: - Private properties

    private let kycApi: KYCApiV3
    private let accountId: AccountId

    private let accountUserBehaviorRelay: BehaviorRelay<KYCUser?> = .init(value: nil)
    private let accountUserLoadingStatusBehaviorRelay: BehaviorRelay<LoadingStatus> = .init(value: .loaded)

    private let kycUsersBehaviorRelay: BehaviorRelay<KYCUsersDictionary> = .init(value: [:])

    private let loadAllUsersController: LoadAllResourcesController<KYC.KycResource> = .init(
        requestPagination: .init(
            .cursorStrategy(
                .init(
                    cursor: nil,
                    limit: 20,
                    order: .descending
                )
            )
        )
    )

    private let internalQueue: DispatchQueue = .init(label: "\(NSStringFromClass(KYCRepo.self))".queueLabel, qos: .userInitiated)

    // MARK: - Public properties

    public var kycUsersValue: [KYCUser] {
        Array(kycUsersBehaviorRelay.value.mapToUsers())
    }

    public var accountUserLoadingStatusValue: LoadingStatus {
        accountUserLoadingStatusBehaviorRelay.value
    }

    public var accountUserValue: KYCUser? {
        accountUserBehaviorRelay.value
    }

    // MARK: -

    init(
        kycApi: KYCApiV3,
        accountId: String
    ) {

        self.kycApi = kycApi
        self.accountId = accountId

        loadAccountUser()
    }
}

// MARK: - Private methods

private extension KYCRepo {

    enum KYCUserState {
        case loading
        case loaded(KYCUser)
        case noUser
    }

    enum LoadUserError: Error {
        case noData
    }
    func loadUser(
        accountId: String,
        completion: @escaping (LoadUserResult) -> Void
    ) {

        self.kycApi.getKycEntry(
            by: accountId,
            completion: { (result) in

                switch result {

                case .failure(let error):
                    completion(.failure(error))

                case .success(let document):
                    guard let data = document.data
                    else {
                        completion(.failure(LoadUserError.noData))
                        return
                    }

                    do {
                        completion(.success(try data.mapToUser()))
                    } catch (let error) {
                        completion(.failure(error))
                    }
                }
            }
        )
    }

    enum LoadManyUsersError: Error {
        case noData
    }
    enum LoadManyUsersResult {
        case failure(Error)
        case success([KYCUser])
    }
    func loadManyUsers(
        accountsIds: [String],
        completion: @escaping (LoadManyUsersResult) -> Void
    ) {

        let cachedAccountIds: [String] = kycUsersValue.map { $0.accountId }
        let filteredAccountIds: [String] = Set(accountsIds).filter({ !cachedAccountIds.contains($0) })

        loadAllUsersController.loadResources(
            loadPage: { [weak self] (pagination, completion) in
                self?.kycApi.postKycEntries(
                    accountIds: filteredAccountIds,
                    pagination: pagination,
                    completion: { (result) in

                        switch result {

                        case .failure(let error):
                            completion(.failed(error))

                        case .success(let document):
                            let data = document.data ?? []
                            pagination.adjustPagination(
                                resultsCount: data.count,
                                links: document.links
                            )
                            completion(.succeeded(data))
                        }
                    }
                )
            },
            completion: { (result, data) in

                switch result {

                case .failed(let error):
                    completion(.failure(error))
                    return

                case .succeded:
                    let users: [KYCUser] = data.compactMap { (resource) in
                        try? resource.mapToUser()
                    }
                    completion(.success(users))
                }
            }
        )
    }

    func updateValue(
        for accountId: AccountId,
        value: KYCUserState
    ) {

        var kycUsers = kycUsersBehaviorRelay.value
        kycUsers[accountId] = value
        kycUsersBehaviorRelay.accept(kycUsers)
    }

    func removeValue(
        for accountId: AccountId
    ) {

        var kycUsers = kycUsersBehaviorRelay.value
        kycUsers[accountId] = nil
        kycUsersBehaviorRelay.accept(kycUsers)
    }
}

// MARK: - Public methods

extension KYCRepo {

    func observeKYCUsers() -> Observable<Set<KYCUser>> {
        kycUsersBehaviorRelay
            .asObservable()
            .map { (dictionary) in
                dictionary.mapToUsers()
        }
    }

    func loadUsers(
        with accountsIds: [String],
        completion: (([KYCUser]) -> Void)? = nil
    ) {

        internalQueue.async { [weak self] in

            var filteredAccountIds: [String] = []

            for accountId in accountsIds {

                switch self?.kycUsersBehaviorRelay.value[accountId] {

                case .loaded,
                     .loading,
                     .noUser:
                    break

                case .none:
                    self?.updateValue(
                        for: accountId,
                        value: .loading
                    )
                    filteredAccountIds.append(accountId)
                }
            }

            self?.loadManyUsers(
                accountsIds: filteredAccountIds,
                completion: { [weak self] (result) in

                    self?.internalQueue.async { [weak self] in

                        switch result {

                        case .success(let users):

                            for accountId in filteredAccountIds {

                                if let user = users.first(where: { $0.accountId == accountId }) {
                                    self?.updateValue(for: accountId, value: .loaded(user))
                                } else {
                                    self?.updateValue(for: accountId, value: .noUser)
                                }
                            }

                        case .failure:

                            for accountId in filteredAccountIds {

                                self?.removeValue(for: accountId)
                            }
                        }

                        completion?(self?.kycUsersValue ?? [])
                    }
            })
        }
    }

    func observeAccountUser() -> Observable<KYCUser?> {
        accountUserBehaviorRelay.asObservable()
    }

    func loadAccountUser(
        completion: ((LoadUserResult) -> Void)? = nil
    ) {

        internalQueue.async { [weak self] in
            self?.accountUserLoadingStatusBehaviorRelay.accept(.loading)
            self?.loadUser(
                accountId: self?.accountId ?? "",
                completion: { [weak self] (result) in

                    self?.internalQueue.async { [weak self] in
                        self?.accountUserLoadingStatusBehaviorRelay.accept(.loaded)

                        switch result {

                        case .failure:
                            break

                        case .success(let user):
                            self?.accountUserBehaviorRelay.accept(user)
                        }

                        completion?(result)
                    }
            })
        }
    }
}

// MARK: - LoadingStatus -

extension KYCRepo {

    enum LoadingStatus {
        case loading
        case loaded
    }
}

// MARK: - KYCUser -

extension KYCRepo {

    struct KYCUser: Hashable {

        let accountId: String
        let firstName: String
        let lastName: String
        let documents: Documents

        func hash(into hasher: inout Hasher) {
            hasher.combine(accountId)
        }

        static func == (lhs: KYCUser, rhs: KYCUser) -> Bool {
            return lhs.accountId == rhs.accountId
                && lhs.firstName == rhs.firstName
                && lhs.lastName == rhs.lastName
                && lhs.documents == rhs.documents
        }
    }
}

extension KYCRepo.KYCUser {

    struct Documents: Equatable {

        let kycAvatar: KYCRepo.KYCUser.Documents.Document
    }
}

// MARK: - Avatar -

extension KYCRepo.KYCUser.Documents {

    struct Document: Equatable {

        let key: String?
        let url: String?
    }
}

private extension KYCRepo {

    struct KYCUserDetails: Decodable {

        let firstName: String
        let lastName: String
        let documents: KYCRepo.KYCUserDetails.Documents
    }
}

extension KYCRepo.KYCUserDetails {

    struct Documents: Decodable, Equatable {

        let kycIdDocument: KYCRepo.KYCUserDetails.Documents.Document
        let kycAvatar: KYCRepo.KYCUserDetails.Documents.Document
    }
}

extension KYCRepo.KYCUserDetails.Documents {

    struct Document: Decodable, Equatable {

        let mimeType: String?
        let key: String?
        let url: String?
        let name: String?
        let type: String?
    }
}

// MARK: - Mappers -

private extension KYC.KycResource {

    private enum UserMapperError: Error {
        case notEnoughData
    }

    func mapToUser() throws -> KYCRepo.KYCUser {

        guard let details = self.details
        else {
            throw UserMapperError.notEnoughData
        }

        let decodedDetails: KYCRepo.KYCUserDetails = try .decode(from: details)

        return .init(
            accountId: self.accountId,
            firstName: decodedDetails.firstName,
            lastName: decodedDetails.lastName,
            documents: .init(
                kycAvatar: .init(
                    key: decodedDetails.documents.kycAvatar.key,
                    url: decodedDetails.documents.kycAvatar.url
                )
            )
        )
    }
}

private extension Dictionary where Key == KYCRepo.AccountId, Value == KYCRepo.KYCUserState {

    func mapToUsers() -> Set<KYCRepo.KYCUser> {

        return Set(compactMap { (state) -> KYCRepo.KYCUser? in
            switch state.value {

            case .loaded(let user):
                return user

            case .loading,
                 .noUser:
                return nil
            }
        })
    }
}
