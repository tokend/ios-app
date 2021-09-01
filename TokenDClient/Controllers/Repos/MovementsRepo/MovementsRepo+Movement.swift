import Foundation
import TokenDSDK
import TokenDWallet

extension MovementsRepo {

    struct Movement {

        let id: MovementIdentifier
        let action: Action
        let amount: Decimal
        let fee: MovementType.Fee
        let assetId: String
        let balanceId: String
        let appliedAt: Date
        let movementType: MovementType
    }
}

extension MovementsRepo.Movement {

    enum Action {

        case locked
        case chargedFromLocked
        case unlocked
        case charged
        case withdrawn
        case matched
        case issued
        case funded
    }
}

// MARK: - Mappers

extension Array where Element == TokenDSDK.Horizon.ParticipantsEffectResource {

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
    case unknownMovementType
    case cannotChooseFundedOrCharged
}

private extension TokenDSDK.Horizon.ParticipantsEffectResource {

    func mapToMovement(
    ) throws -> MovementsRepo.Movement {

        guard let id = self.id,
              let balanceId = self.balance?.id,
              let operation = self.operation,
              let operationDetails = operation.details,
              let effect = self.effect
        else {
            throw MovementMapperError.notEnoughData
        }

        let amount: Decimal
        let fee: MovementsRepo.Movement.MovementType.Fee
        let assetId: String
        
        let action: MovementsRepo.Movement.Action
        let movementType: MovementsRepo.Movement.MovementType
        
        switch effect.baseEffectType {

        case .effectBalanceChange(let balanceChangeResource):
            
            amount = balanceChangeResource.amount
            
            guard let balanceChangeResourceFee = balanceChangeResource.fee,
                  let balanceChangeResourceAssetId = self.asset?.id
            else {
                throw MovementMapperError.notEnoughData
            }
            
            fee = .init(resource: balanceChangeResourceFee)
            assetId = balanceChangeResourceAssetId

            switch balanceChangeResource.effectBalanceChangeType {
            
            case .effectsLocked:
                action = .locked
                
            case .effectsChargedFromLocked:
                action = .chargedFromLocked
                
            case .effectsUnlocked:
                action = .unlocked
                 
            case .effectsCharged:
                action = .charged
                
            case .effectsWithdrawn:
                action = .withdrawn
                
            case .effectsIssued:
                action = .issued

            case .effectsFunded:
                action = .funded

            case .`self`:
                throw MovementMapperError.unknownEffectType
            }

        case .effectMatched(let matchedResource):
            
            if let charged = matchedResource.charged,
               balanceId == charged.balanceAddress {

                amount = charged.amount
                fee = .init(resource: charged.fee)
                assetId = charged.assetCode
            } else if let funded = matchedResource.funded,
                      balanceId == funded.balanceAddress {
                
                amount = funded.amount
                fee = .init(resource: funded.fee)
                assetId = funded.assetCode
            } else {
                throw MovementMapperError.cannotChooseFundedOrCharged
            }
            
            action = .matched
            
        case .`self`:
            throw MovementMapperError.unknownEffectType
        }

        if let resource = operationDetails as? Horizon.PaymentOpResource {
            movementType = .payment(try .init(resource: resource))
        } else if let resource = operationDetails as? Horizon.CreateIssuanceRequestOpResource {
            movementType = .issuance(.init(resource: resource))
        } else if let resource = operationDetails as? Horizon.CreateWithdrawRequestOpResource {
            movementType = .withdrawalRequest(try .init(resource: resource))
        } else if let resource = operationDetails as? Horizon.ManageOfferOpResource {
            if let effect = effect as? Horizon.EffectMatchedResource {
                movementType = .investment(try .init(effect: effect))
            } else if effect is Horizon.EffectsUnlockedResource {
                movementType = .offerCancellation
            } else {
                movementType = .offer(try .init(resource: resource))
            }
        } else if operationDetails is Horizon.CheckSaleStateOpResource {
            if let effect = effect as? Horizon.EffectMatchedResource {
                movementType = .investment(try .init(effect: effect))
            } else if effect is Horizon.EffectsIssuedResource {
                movementType = .issuance(.init(cause: nil, reference: nil))
            } else if effect is Horizon.EffectsUnlockedResource {
                movementType = .saleCancellation
            } else {
                throw MovementMapperError.unknownMovementType
            }
        } else if let resource = operationDetails as? Horizon.CreateAmlAlertRequestOpResource {
            movementType = .amlAlert(.init(resource: resource))
        } else if let resource = operationDetails as? Horizon.ManageAssetPairOpResource {
            movementType = .assetPairUpdate(try .init(resource: resource))
        } else if operationDetails is Horizon.CreateAtomicSwapAskRequestOpResource {
            movementType = .atomicSwapAskCreation
        } else if operationDetails is Horizon.CreateAtomicSwapBidRequestOpResource {
            movementType = .atomicSwapBidCreation
        } else {
            throw MovementMapperError.unknownOperationType
        }
        
        return .init(
            id: id,
            action: action,
            amount: amount,
            fee: fee,
            assetId: assetId,
            balanceId: balanceId,
            appliedAt: operation.appliedAt,
            movementType: movementType
        )
    }
}
