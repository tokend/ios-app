import UIKit
import RxCocoa
import RxSwift
import TokenDSDK

extension TransactionDetails {
    class OperationSectionsProvider {
        
        private let transactionsHistoryRepo: TransactionsHistoryRepo
        private let identifier: UInt64
        private let accountId: String
        
        private let dateFormatter = TransactionDetails.DateFormatter()
        private let amountFormatter = TransactionDetails.AmountFormatter()
        
        init(
            transactionsHistoryRepo: TransactionsHistoryRepo,
            identifier: UInt64,
            accountId: String
            ) {
            
            self.transactionsHistoryRepo = transactionsHistoryRepo
            self.identifier = identifier
            self.accountId = accountId
        }
        
        // MARK: - Private
        
        private func loadDataSections(
            participantEffect: ParticipantEffectResource
            ) -> [TransactionDetails.Model.SectionModel] {
            
            guard let operation = participantEffect.operation,
                let effect = participantEffect.effect else {
                    return []
            }
            
            switch effect.effectType {
                
            case .effectBalanceChange(let balanceChangeEffect):
                return self.sectionsForBalanceChangeEffect(
                    participantEffect: participantEffect,
                    balanceChangeEffect: balanceChangeEffect,
                    operation: operation
                )
                
            case .effectMatched(let matchedEffect):
                return self.sectionsForMatchedEffect(
                    participantEffect: participantEffect,
                    matchedEffect: matchedEffect,
                    operation: operation
                )
                
            case .self:
                return []
            }
        }
        
        private func sectionsForBalanceChangeEffect(
            participantEffect: ParticipantEffectResource,
            balanceChangeEffect: EffectBalanceChangeResource,
            operation: OperationResource
            ) -> [TransactionDetails.Model.SectionModel] {
            
            var sections: [TransactionDetails.Model.SectionModel] = []
            
            guard let assetResource = participantEffect.asset,
                let asset = assetResource.id,
                let fee = balanceChangeEffect.fee,
                let details = operation.details else {
                    return sections
            }
            
            let effectSection = self.createTitleSection(balanceChangeEffect: balanceChangeEffect)
            sections.append(effectSection)
            
            let totalAmount: TransactionDetails.Model.Amount
            switch balanceChangeEffect.effectBalanceChangeType {
                
            case .effectCharged,
                 .effectLocked,
                 .effectUnlocked,
                 .effectChargedFromLocked,
                 .effectWithdrawn:
                
                totalAmount = TransactionDetails.Model.Amount.init(
                    value: balanceChangeEffect.amount + fee.fixed + fee.calculatedPercent,
                    asset: asset
                )
                
            case .effectFunded,
                 .effectIssued:
                
                totalAmount = TransactionDetails.Model.Amount.init(
                    value: balanceChangeEffect.amount - fee.fixed - fee.calculatedPercent,
                    asset: asset
                )
                
            case .`self`:
                totalAmount = TransactionDetails.Model.Amount.init(
                    value: 0,
                    asset: asset
                )
            }
            
            let totalCell = TransactionDetails.Model.CellModel.init(
                title: Localized(.total),
                value: self.amountFormatter.formatAmount(totalAmount),
                identifier: .total
            )
            
            let amount = TransactionDetails.Model.Amount.init(
                value: balanceChangeEffect.amount,
                asset: asset
            )
            
            let amountCell = TransactionDetails.Model.CellModel(
                title: Localized(.amount),
                value: self.amountFormatter.formatAmount(amount),
                identifier: .amount
            )
            
            let fixedFeeAmount = TransactionDetails.Model.Amount.init(
                value: fee.fixed,
                asset: asset
            )
            
            let fixedFeeCell = TransactionDetails.Model.CellModel(
                title: Localized(.fixed_fee),
                value: self.amountFormatter.formatAmount(fixedFeeAmount),
                identifier: .fee
            )
            
            let percentFeeAmount = TransactionDetails.Model.Amount.init(
                value: fee.calculatedPercent,
                asset: asset
            )
            
            let percentFeeCell = TransactionDetails.Model.CellModel(
                title: Localized(.percent_fee),
                value: self.amountFormatter.formatAmount(percentFeeAmount),
                identifier: .fee
            )
            
            let operationSection = TransactionDetails.Model.SectionModel.init(
                title: "",
                cells: [totalCell, amountCell, fixedFeeCell, percentFeeCell],
                description: ""
            )
            sections.append(operationSection)
            
            if let descriptionSection = self.createDescriptionSection(
                details: details,
                balanceChangeEffect: balanceChangeEffect
                ) {
                sections.append(descriptionSection)
            }
            
            let dateSection = self.createDateSection(date: operation.appliedAt)
            sections.append(dateSection)
            
            return sections
        }
        
        private func sectionsForMatchedEffect(
            participantEffect: ParticipantEffectResource,
            matchedEffect: EffectMatchedResource,
            operation: OperationResource
            ) -> [TransactionDetails.Model.SectionModel] {
            
            guard let funded = matchedEffect.funded,
                let charged = matchedEffect.charged,
                let details = operation.details else {
                    return []
            }
            
            var sections: [TransactionDetails.Model.SectionModel] = []
            
            let effectCell = TransactionDetails.Model.CellModel.init(
                title: Localized(.effect),
                value: Localized(.matched),
                identifier: .effect
            )
            
            let effectSection = TransactionDetails.Model.SectionModel.init(
                title: "",
                cells: [effectCell],
                description: ""
            )
            sections.append(effectSection)
            
            let totalChargedAmount = TransactionDetails.Model.Amount.init(
                value: charged.amount + charged.fee.fixed,
                asset: charged.assetCode
            )
            
            let totalChargedCell = TransactionDetails.Model.CellModel.init(
                title: Localized(.charged),
                value: self.amountFormatter.formatAmount(totalChargedAmount),
                identifier: .paid
            )
            
            let chargedAmount = TransactionDetails.Model.Amount.init(
                value: charged.amount,
                asset: charged.assetCode
            )
            
            let chargedAmountCell = TransactionDetails.Model.CellModel.init(
                title: Localized(.amount),
                value: self.amountFormatter.formatAmount(chargedAmount),
                identifier: .amount
            )
            
            let chargedFee = TransactionDetails.Model.Amount.init(
                value: charged.fee.fixed,
                asset: charged.assetCode
            )
            
            let chargedFeeCell = TransactionDetails.Model.CellModel.init(
                title: Localized(.fee),
                value: self.amountFormatter.formatAmount(chargedFee),
                identifier: .fee
            )
            
            let chargedSection = TransactionDetails.Model.SectionModel.init(
                title: "",
                cells: [
                    totalChargedCell,
                    chargedAmountCell,
                    chargedFeeCell
                ],
                description: ""
            )
            sections.append(chargedSection)
            
            let totalFundedAmount = TransactionDetails.Model.Amount.init(
                value: funded.amount - funded.fee.fixed,
                asset: funded.assetCode
            )
            
            let totalFundedCell = TransactionDetails.Model.CellModel.init(
                title: Localized(.funded),
                value: self.amountFormatter.formatAmount(totalFundedAmount),
                identifier: .received
            )
            
            let fundedAmount = TransactionDetails.Model.Amount.init(
                value: funded.amount,
                asset: funded.assetCode
            )
            
            let fundedAmountCell = TransactionDetails.Model.CellModel.init(
                title: Localized(.amount),
                value: self.amountFormatter.formatAmount(fundedAmount),
                identifier: .amount
            )
            
            let fundedFee = TransactionDetails.Model.Amount.init(
                value: funded.fee.fixed,
                asset: funded.assetCode
            )
            
            let fundedFeeCell = TransactionDetails.Model.CellModel.init(
                title: Localized(.fee),
                value: self.amountFormatter.formatAmount(fundedFee),
                identifier: .fee
            )
            
            let fundedSection = TransactionDetails.Model.SectionModel.init(
                title: "",
                cells: [
                    totalFundedCell,
                    fundedAmountCell,
                    fundedFeeCell
                ],
                description: ""
            )
            sections.append(fundedSection)
            
            if let priceSection = self.createPriceSection(
                details: details,
                matchedEffect: matchedEffect
                ) {
                
                sections.append(priceSection)
            }
            
            let dateSection = self.createDateSection(date: operation.appliedAt)
            sections.append(dateSection)
            
            return sections
        }
        
        private func createDateSection(date: Date) -> TransactionDetails.Model.SectionModel {
            let dateCell = TransactionDetails.Model.CellModel(
                title: self.dateFormatter.dateToString(date: date),
                value: "",
                identifier: .date
            )
            let dateSection = TransactionDetails.Model.SectionModel(
                title: Localized(.date),
                cells: [dateCell],
                description: ""
            )
            return dateSection
        }
        
        private func createDescriptionSection(
            details: OperationDetailsResource,
            balanceChangeEffect: EffectBalanceChangeResource
            ) -> TransactionDetails.Model.SectionModel? {
            
            var descriptionCells: [TransactionDetails.Model.CellModel] = []
            
            switch details.operationDetailsRelatedToBalance {
                
            case .opCreateWithdrawRequestDetails(let withdraw):
                guard let address = withdraw.creatorDetails["address"] as? String else {
                    return nil
                }
                let addressCell = TransactionDetails.Model.CellModel(
                    title: Localized(.destination_address),
                    value: address,
                    identifier: .description
                )
                descriptionCells.append(addressCell)
                
            case .opPaymentDetails(let payment):
                if !payment.subject.isEmpty {
                    let subjectCell = TransactionDetails.Model.CellModel(
                        title: Localized(.subject),
                        value: payment.subject,
                        identifier: .subject
                    )
                    descriptionCells.append(subjectCell)
                }
                
                if balanceChangeEffect as? EffectChargedResource != nil,
                    let toAccount = payment.accountTo,
                    let toAccountId = toAccount.id {
                    let accountToCell = TransactionDetails.Model.CellModel(
                        title: Localized(.to_account),
                        value: toAccountId,
                        identifier: .toAccount
                    )
                    descriptionCells.append(accountToCell)
                } else if balanceChangeEffect as? EffectFundedResource != nil,
                    let fromAccount = payment.accountFrom,
                    let fromAccountId = fromAccount.id {
                    let accountFromCell = TransactionDetails.Model.CellModel(
                        title: Localized(.from_account),
                        value: fromAccountId,
                        identifier: .toAccount
                    )
                    descriptionCells.append(accountFromCell)
                }
                
            case .opCreateAMLAlertRequestDetails,
                 .opCreateAtomicSwapBidRequestDetails,
                 .opPayoutDetails,
                 .opCreateIssuanceRequestDetails,
                 .`self`:
                
                return nil
            }
            
            guard !descriptionCells.isEmpty else {
                return nil
            }
            
            let descriptionSection = TransactionDetails.Model.SectionModel(
                title: Localized(.description),
                cells: descriptionCells,
                description: ""
            )
            
            return descriptionSection
        }
        
        private func createTitleSection(
            balanceChangeEffect: EffectBalanceChangeResource
            ) -> TransactionDetails.Model.SectionModel {
            
            var effectCellValue: String?
            
            switch balanceChangeEffect.effectBalanceChangeType {
                
            case .effectCharged:
                effectCellValue = Localized(.charged)
                
            case .effectChargedFromLocked:
                effectCellValue = Localized(.charged_from_lock)
                
            case .effectFunded:
                effectCellValue = Localized(.funded)
                
            case .effectIssued:
                effectCellValue = Localized(.issued)
                
            case .effectLocked:
                effectCellValue = Localized(.locked)
                
            case .effectUnlocked:
                effectCellValue = Localized(.unlocked)
                
            case .effectWithdrawn:
                effectCellValue = Localized(.withdrawn)
                
            case .`self`:
                break
            }
            
            let effectCell = TransactionDetails.Model.CellModel(
                title: Localized(.effect),
                value: effectCellValue ?? Localized(.unknown),
                identifier: .effect
            )
            
            return TransactionDetails.Model.SectionModel(
                title: "",
                cells: [effectCell],
                description: ""
            )
        }
        
        private func createPriceSection(
            details: OperationDetailsResource,
            matchedEffect: EffectMatchedResource
            ) -> TransactionDetails.Model.SectionModel? {
            
            var baseAsset: String
            var quoteAsset: String
            
            if let manageOffer = details as? OpManageOfferDetailsResource {
                guard let baseAssetResource = manageOffer.baseAsset,
                    let manageOfferBaseAsset = baseAssetResource.id,
                    let quoteAssetResource = manageOffer.quoteAsset,
                    let manageOfferQuoteAsset = quoteAssetResource.id else {
                        return nil
                }
                
                baseAsset = manageOfferBaseAsset
                quoteAsset = manageOfferQuoteAsset
                
            } else if details as? OpCheckSaleStateDetailsResource != nil {
                guard let charged = matchedEffect.charged,
                    let funded = matchedEffect.funded else {
                        return nil
                }
                
                baseAsset = funded.assetCode
                quoteAsset = charged.assetCode
            } else {
                return nil
            }
            
            let priceCell = TransactionDetails.Model.CellModel.init(
                title: Localized(.price),
                value: Localized(
                    .one_for,
                    replace: [
                        .one_for_replace_base_asset: baseAsset,
                        .one_for_replace_quote_asset: quoteAsset,
                        .one_for_replace_sale_invest_price_amount: matchedEffect.price
                    ]
                ),
                identifier: .price
            )
            
            return TransactionDetails.Model.SectionModel.init(
                title: "",
                cells: [priceCell],
                description: ""
            )
        }
    }
}

extension TransactionDetails.OperationSectionsProvider: TransactionDetails.SectionsProviderProtocol {
    
    func observeTransaction() -> Observable<[TransactionDetails.Model.SectionModel]> {
        return self.transactionsHistoryRepo
            .observeHistory()
            .map { [weak self] (effects) -> [TransactionDetails.Model.SectionModel] in
                guard let effect = effects.first(where: { (effect) -> Bool in
                    guard let effectId = effect.id,
                        let effectIdUInt64 = UInt64(effectId),
                        let identifier = self?.identifier else {
                            return false
                    }
                    
                    return identifier == effectIdUInt64
                }) else {
                    return []
                }
                
                return self?.loadDataSections(participantEffect: effect) ?? []
        }
    }
    
    func getActions() -> [TransactionDetailsProviderProtocol.Action] {
        return []
    }
    
    func performActionWithId(
        _ id: String,
        onSuccess: @escaping () -> Void,
        onShowLoading: @escaping () -> Void,
        onHideLoading: @escaping () -> Void,
        onError: @escaping (String) -> Void
        ) { }
}
