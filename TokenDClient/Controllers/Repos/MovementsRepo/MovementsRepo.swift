import Foundation
import TokenDSDK
import TokenDWallet
import RxSwift
import RxCocoa
import DLJSONAPI

class MovementsRepo {

    typealias MovementIdentifier = String

    enum LoadingStatus {
        case loading
        case loaded
    }
    
    private enum RequestFilter {
        
        case balanceId(String)
        case accountId(String)
    }

    // MARK: - Private properties

    private let api: HistoryApiV3
    private let originalAccountId: String
    private let requestFilter: RequestFilter

    private let movementsBehaviorRelay: BehaviorRelay<[Movement]> = BehaviorRelay(value: [])
    private let loadingStatusBehaviorRelay: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)

    private let loadAllMovementsController: LoadAllResourcesController<TokenDSDK.Horizon.ParticipantsEffectResource> = .init(
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

    // MARK: - Includes

    private let effect: String = "effect"
    private let operationDetails: String = "operation.details"
    private let operation: String = "operation"

    // MARK: - Public propeties

    public var movements: [Movement] {
        return self.movementsBehaviorRelay.value
    }

    public var loadingStatus: LoadingStatus {
        return self.loadingStatusBehaviorRelay.value
    }

    // MARK: -

    init(
        api: HistoryApiV3,
        originalAccountId: String
        ) {

        self.api = api
        self.originalAccountId = originalAccountId
        self.requestFilter = .accountId(originalAccountId)

        loadAllMovements(completion: nil)
    }
    
    init(
        api: HistoryApiV3,
        originalAccountId: String,
        balanceId: String
    ) {
        
        self.api = api
        self.originalAccountId = originalAccountId
        self.requestFilter = .balanceId(balanceId)

        loadAllMovements(completion: nil)
    }
}

// MARK: - Public methods

extension MovementsRepo {

    func observeMovements() -> Observable<[Movement]> {
        return self.movementsBehaviorRelay.asObservable()
    }

    func observeLoadingStatus() -> Observable<LoadingStatus> {
        return self.loadingStatusBehaviorRelay.asObservable()
    }

    func loadAllMovements(
        completion: (() -> Void)?
    ) {

        guard loadingStatus != .loading else { return }
        loadingStatusBehaviorRelay.accept(.loading)

        let filters: MovementsRequestFilterV3
        
        switch requestFilter {
        
        case .accountId(let accountId):
            filters = .init().addFilter(.account(accountId))
            
        case .balanceId(let balanceId):
            filters = .init().addFilter(.balance(balanceId))
        }
        
        let include: [String] = [self.effect, self.operationDetails, self.operation]

        loadAllMovementsController.loadResources(
            loadPage: { [weak self] (pagination, completion) in
                self?.api.requestMovements(
                    filters: filters,
                    include: include,
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
            completion: { [weak self] (result, data) in

                self?.loadingStatusBehaviorRelay.accept(.loaded)

                switch result {

                case .failed:
                    break

                case .succeded:
                    break
                }

                guard let movements = try? data.mapToMovements() else {
                    return
                }
                self?.movementsBehaviorRelay.accept(movements)
                completion?()
            }
        )
    }
}
