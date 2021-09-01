import Foundation
import TokenDSDK
import TokenDWallet

extension MovementsRepo.Movement {
    
    enum MovementType {
        
        case amlAlert(AmlAlert)
        case offer(Offer)
        case matchedOffer(MatchedOffer)
        case investment(Investment)
        case saleCancellation
        case offerCancellation
        case issuance(Issuance)
        case payment(Payment)
        case withdrawalRequest(WithdrawalRequest)
        case assetPairUpdate(AssetPairUpdate)
        case atomicSwapAskCreation
        case atomicSwapBidCreation
    }
}

extension MovementsRepo.Movement.MovementType {
    
    struct AmlAlert {
        
        let reason: String?
        
        init(
            resource: Horizon.CreateAmlAlertRequestOpResource
        ) {
            
            let reason: String? = resource.creatorDetails["reason"] as? String
            
            self.reason = reason?.isEmpty == true ? nil : reason
        }
    }
}

extension MovementsRepo.Movement.MovementType {
    
    class Offer {
        
        let offerId: Int64
        let orderBookId: Int64
        let price: Decimal
        let isBuy: Bool
        let baseAmount: Decimal
        let baseAssetId: String
        let quoteAssetId: String
        let fee: Fee
        
        internal init(
            offerId: Int64,
            orderBookId: Int64,
            price: Decimal,
            isBuy: Bool,
            baseAmount: Decimal,
            baseAssetId: String,
            quoteAssetId: String,
            fee: MovementsRepo.Movement.MovementType.Fee
        ) {
            
            self.offerId = offerId
            self.orderBookId = orderBookId
            self.price = price
            self.isBuy = isBuy
            self.baseAmount = baseAmount
            self.baseAssetId = baseAssetId
            self.quoteAssetId = quoteAssetId
            self.fee = fee
        }
        
        
        enum InitError: Swift.Error {
            case notEnoughData
        }
        convenience init(
            resource: Horizon.ManageOfferOpResource
        ) throws {
            
            guard let baseAssetId = resource.baseAsset?.id,
                  let quoteAssetId = resource.quoteAsset?.id,
                  let fee = resource.fee
            else {
                throw InitError.notEnoughData
            }
            
            self.init(
                offerId: resource.offerId,
                orderBookId: resource.orderBookId,
                price: resource.price,
                isBuy: resource.isBuy,
                baseAmount: resource.baseAmount,
                baseAssetId: baseAssetId,
                quoteAssetId: quoteAssetId,
                fee: .init(resource: fee)
            )
        }
        
        struct BalanceChangeDetails {
            
            let amount: Decimal
            let fee: Fee
            let balanceId: String
            let assetId: String
            
            init(
                resource: Horizon.ParticularBalanceChangeEffect
            ) {
                
                self.amount = resource.amount
                self.fee = .init(resource: resource.fee)
                self.balanceId = resource.balanceAddress
                self.assetId = resource.assetCode
            }
        }
    }
}

extension MovementsRepo.Movement.MovementType {

    class MatchedOffer: Offer {

        let charged: BalanceChangeDetails
        let funded: BalanceChangeDetails

        enum InitError: Swift.Error {

            case notEnoughData
        }
        
        init(
            resource: Horizon.ManageOfferOpResource,
            effect: Horizon.EffectMatchedResource
        ) throws {

            guard let charged = effect.charged,
                  let funded = effect.funded,
                  let baseAssetId = resource.baseAsset?.id,
                  let quoteAssetId = resource.quoteAsset?.id,
                  let fee = resource.fee
            else {
                throw InitError.notEnoughData
            }

            self.charged = .init(resource: charged)
            self.funded = .init(resource: funded)
            
            super.init(
                offerId: resource.offerId,
                orderBookId: resource.orderBookId,
                price: resource.price,
                isBuy: resource.isBuy,
                baseAmount: resource.baseAmount,
                baseAssetId: baseAssetId,
                quoteAssetId: quoteAssetId,
                fee: .init(resource: fee)
            )
        }

        internal init(
            offerId: Int64,
            orderBookId: Int64,
            price: Decimal,
            isBuy: Bool,
            baseAmount: Decimal,
            baseAssetId: String,
            quoteAssetId: String,
            fee: MovementsRepo.Movement.MovementType.Fee,
            charged: MovementsRepo.Movement.MovementType.Offer.BalanceChangeDetails,
            funded: MovementsRepo.Movement.MovementType.Offer.BalanceChangeDetails
        ) {

            self.charged = charged
            self.funded = funded

            super.init(
                offerId: offerId,
                orderBookId: orderBookId,
                price: price,
                isBuy: isBuy,
                baseAmount: baseAmount,
                baseAssetId: baseAssetId,
                quoteAssetId: quoteAssetId,
                fee: fee
            )
        }
    }
}

extension MovementsRepo.Movement.MovementType {

    class Investment: MatchedOffer {

        enum InitError: Swift.Error {
            case notEnoughData
        }
        init(
            effect: Horizon.EffectMatchedResource
        ) throws {

            guard let charged = effect.charged,
                  let funded = effect.funded
            else {
                throw InitError.notEnoughData
            }

            super.init(
                offerId: effect.offerId,
                orderBookId: effect.orderBookId,
                price: effect.price,
                isBuy: true,
                baseAmount: funded.amount,
                baseAssetId: funded.assetCode,
                quoteAssetId: charged.assetCode,
                fee: .init(resource: charged.fee),
                charged: .init(resource: charged),
                funded: .init(resource: funded)
            )
        }
    }
}

extension MovementsRepo.Movement.MovementType {
    
    struct Issuance {
        
        let cause: String?
        let reference: String?
        
        init(
            cause: String?,
            reference: String?
        ) {
            
            self.cause = cause
            self.reference = reference
        }
        
        init(
            resource: Horizon.CreateIssuanceRequestOpResource
        ) {
            
            self.init(
                cause: resource.creatorDetails["cause"] as? String,
                reference: resource.reference
            )
        }
    }
}

extension MovementsRepo.Movement.MovementType {
    
    struct Payment {
        
        let sourceAccountId: String
        let destinationAccountId: String
        let sourceFee: Fee
        let destinationFee: Fee
        let sourcePayForDestination: Bool
        let subject: String?
        
        enum InitError: Swift.Error {
            
            case notEnoughData
        }
        init(
            resource: Horizon.PaymentOpResource
        ) throws {
            
            guard let sourceAccountId = resource.accountFrom?.id,
                  let destinationAccountId = resource.accountTo?.id,
                  let sourceFee = resource.sourceFee,
                  let destinationFee = resource.destinationFee
            else {
                throw InitError.notEnoughData
            }
            
            self.sourceAccountId = sourceAccountId
            self.destinationAccountId = destinationAccountId
            self.sourceFee = .init(resource: sourceFee)
            self.destinationFee = .init(resource: destinationFee)
            self.sourcePayForDestination = resource.sourcePayForDestination
            self.subject = resource.subject.isEmpty ? nil : resource.subject
        }
    }
}

extension MovementsRepo.Movement.MovementType {
    
    struct WithdrawalRequest {
        
        let destinationAddress: String
        
        enum InitError: Swift.Error {
            case notEnoughData
        }
        init(
            resource: Horizon.CreateWithdrawRequestOpResource
        ) throws {
            
            guard let address = resource.creatorDetails["address"] as? String
            else {
                throw InitError.notEnoughData
            }
            
            self.destinationAddress = address
        }
    }
}

extension MovementsRepo.Movement.MovementType {
    
    struct AssetPairUpdate {
        
        let baseAssetId: String
        let quoteAssetId: String
        let physicalPrice: Decimal
        let policy: Int32
        
        enum InitError: Swift.Error {
            case notEnoughData
        }
        init(
            resource: Horizon.ManageAssetPairOpResource
        ) throws {
            
            guard let baseAssetId = resource.baseAsset?.id,
                  let quoteAssetId = resource.quoteAsset?.id
            else {
                throw InitError.notEnoughData
            }
            
            self.baseAssetId = baseAssetId
            self.quoteAssetId = quoteAssetId
            self.physicalPrice = resource.physicalPrice
            self.policy = resource.policies?.value ?? 0
        }
    }
}

extension MovementsRepo.Movement.MovementType {
    
    struct Fee {
        
        let fixed: Decimal
        let percent: Decimal
        
        init(
            resource: Horizon.Fee
        ) {
            
            self.fixed = resource.fixed
            self.percent = resource.calculatedPercent
        }
    }
}
