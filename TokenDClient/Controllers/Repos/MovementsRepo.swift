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

    // MARK: - Private properties

    private let api: HistoryApiV3
    private let originalAccountId: String

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
        accountId: String
        ) {

        self.api = api
        self.originalAccountId = accountId

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

        let filters = MovementsRequestFilterV3().addFilter(.account(originalAccountId))
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

// MARK: - Movement

extension MovementsRepo {

    struct Movement {

        let id: MovementIdentifier
        let assetId: String
        let amount: Decimal
        let eventType: EventType
        let appliedAt: Date
        let accountIdFrom: String?

        var placeId: String { assetId }
    }
}

extension MovementsRepo.Movement {

    enum EventType {

        case received
        case redeemed
    }
}

// MARK: - Mappers

private extension Array where Element == TokenDSDK.Horizon.ParticipantsEffectResource {

    func mapToMovements(
    ) throws -> [MovementsRepo.Movement] {

        try compactMap { (movement) in
            do {
                return try movement.mapToMovement()
            } catch (let error) {

                switch error {

                case MovementMapperError.unknownOperationType,
                     MovementMapperError.unknownEffectType:
                    return nil

                default:
                    throw error
                }
            }
        }
    }
}

private enum MovementMapperError: Swift.Error {
    case notEnoughData
    case unknownOperationType
    case unknownEffectType
}

private extension TokenDSDK.Horizon.ParticipantsEffectResource {

    func mapToMovement(
    ) throws -> MovementsRepo.Movement {

        guard let id = self.id,
              let assetId = self.asset?.id,
              let operation = self.operation,
              let operationDetails = operation.details,
              let effect = self.effect
        else {
            throw MovementMapperError.notEnoughData
        }

        let amount: Decimal
        let eventType: MovementsRepo.Movement.EventType
        let accountIdFrom: String?

        if let payment = operationDetails as? Horizon.PaymentOpResource {

            amount = payment.amount
            accountIdFrom = payment.accountFrom?.id

            switch effect.baseEffectType {

            case .effectBalanceChange(let balanceChangeResource):

                switch balanceChangeResource.effectBalanceChangeType {

                case .effectsCharged:
                    if payment.subject == "Redemption" {
                        eventType = .redeemed
                    } else {
                        throw MovementMapperError.unknownEffectType
                    }

                case .effectsFunded:
                    eventType = .received

                case .effectsChargedFromLocked,
                     .effectsIssued,
                     .effectsLocked,
                     .effectsUnlocked,
                     .effectsWithdrawn,
                     .`self`:

                    throw MovementMapperError.unknownEffectType
                }

            case .effectMatched,
                 .`self`:
                throw MovementMapperError.unknownEffectType
            }

        } else if let issuance = operationDetails as? Horizon.CreateIssuanceRequestOpResource {

            amount = issuance.amount
            eventType = .received
            accountIdFrom = nil

        } else {

            throw MovementMapperError.unknownOperationType
        }

        return .init(
            id: id,
            assetId: assetId,
            amount: amount,
            eventType: eventType,
            appliedAt: operation.appliedAt,
            accountIdFrom: accountIdFrom
        )
    }
}
