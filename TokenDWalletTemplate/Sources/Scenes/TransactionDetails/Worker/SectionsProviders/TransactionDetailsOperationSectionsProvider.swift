import UIKit
import RxCocoa
import RxSwift
import TokenDSDK

// swiftlint:disable file_length
extension TransactionDetails {
    // swiftlint:disable type_body_length
    class OperationSectionsProvider {
        
        private let transactionsProvider: TransactionsProviderProtocol
        private let identifier: UInt64
        private let accountId: String
        
        private let dateFormatter = TransactionDetails.DateFormatter()
        private let amountFormatter = TransactionDetails.AmountFormatter()
        private let emailFetcher: TransactionDetails.EmailFetcherProtocol
        
        private let sectionsRelay: BehaviorRelay<[Model.SectionModel]> = BehaviorRelay(value: [])
        private let disposeBag: DisposeBag = DisposeBag()
        
        private var effect: ParticipantEffectResource?
        private var counterpartyEmail: String?
        
        init(
            transactionsProvider: TransactionsProviderProtocol,
            emailFetcher: TransactionDetails.EmailFetcherProtocol,
            identifier: UInt64,
            accountId: String
            ) {
            
            self.transactionsProvider = transactionsProvider
            self.emailFetcher = emailFetcher
            self.identifier = identifier
            self.accountId = accountId
        }
        
        // MARK: - Private
        
        private func loadDataSections() {
            guard let participantEffect = self.effect,
                let operation = participantEffect.operation,
                let effect = participantEffect.effect else {
                    return
            }
            
            var sections: [Model.SectionModel] = []
            switch effect.effectType {
                
            case .effectBalanceChange(let balanceChangeEffect):
                let balancesSections = self.sectionsForBalanceChangeEffect(
                    participantEffect: participantEffect,
                    balanceChangeEffect: balanceChangeEffect,
                    operation: operation
                )
                sections.append(contentsOf: balancesSections)
                
            case .effectMatched(let matchedEffect):
                let macthedSections = self.sectionsForMatchedEffect(
                    participantEffect: participantEffect,
                    matchedEffect: matchedEffect,
                    operation: operation
                )
                sections.append(contentsOf: macthedSections)
                
            case .`self`:
                break
            }
            
            self.sectionsRelay.accept(sections)
        }
        
        private func sectionsForBalanceChangeEffect(
            participantEffect: ParticipantEffectResource,
            balanceChangeEffect: EffectBalanceChangeResource,
            operation: OperationResource
            ) -> [TransactionDetails.Model.SectionModel] {
            
            guard let assetResource = participantEffect.asset,
                let asset = assetResource.id,
                let details = operation.details else {
                    return []
            }
            var sections: [Model.SectionModel] = []
            
            if let operationDetails = details as? OpManageOfferDetailsResource {
                return self.sectionsForManageOfferOperation(
                    participantEffect: participantEffect,
                    operation: operation,
                    details: operationDetails
                )
            }
            
            var cells: [Model.CellModel] = []
            let effectCell = self.createTitleCell(balanceChangeEffect: balanceChangeEffect)
            cells.append(effectCell)
            
            let amount: TransactionDetails.Model.Amount
            switch balanceChangeEffect.effectBalanceChangeType {
                
            case .effectCharged,
                 .effectLocked,
                 .effectUnlocked,
                 .effectChargedFromLocked,
                 .effectWithdrawn:
                
                amount = TransactionDetails.Model.Amount(
                    value: balanceChangeEffect.amount,
                    asset: asset
                )
                
            case .effectFunded,
                 .effectIssued:
                
                amount = TransactionDetails.Model.Amount(
                    value: balanceChangeEffect.amount,
                    asset: asset
                )
                
            case .`self`:
                amount = TransactionDetails.Model.Amount(
                    value: 0,
                    asset: asset
                )
            }
            
            let descriptionCell = self.createDescriptionCells(
                details: details,
                balanceChangeEffect: balanceChangeEffect
            )
            cells.append(contentsOf: descriptionCell)
            
            let amountCell = TransactionDetails.Model.CellModel(
                title: self.amountFormatter.formatAmount(amount),
                hint: Localized(.amount),
                identifier: .amount
            )
            cells.append(amountCell)
            
            let paymentFees = self.createPaymentFeeCell(
                details: details,
                balanceChangeEffect: balanceChangeEffect
            )
            if !paymentFees.isEmpty {
                if let index = cells.indexOf(amountCell) {
                    cells[index].isSeparatorHidden = true
                }
                cells.append(contentsOf: paymentFees)
            }
            
            let detailsCells = self.createDetailsCells(
                details: details,
                balanceChangeEffect: balanceChangeEffect
            )
            cells.append(contentsOf: detailsCells)
            
            let dateCell = self.createDateCell(date: operation.appliedAt)
            cells.append(dateCell)
            
            let infoSection = TransactionDetails.Model.SectionModel(
                title: "",
                cells: cells,
                description: ""
            )
            sections.append(infoSection)
            if let manageAssetPairDetails = details as? OpManageAssetPairDetailsResource,
                let assetPairsSection = self.createManageAssetPairDetailsSection(
                    details: manageAssetPairDetails
                ) {
                
                sections.append(assetPairsSection)
            }
            
            return sections
        }
        
        private func sectionsForManageOfferOperation(
            participantEffect: ParticipantEffectResource,
            operation: OperationResource,
            details: OpManageOfferDetailsResource
            ) -> [TransactionDetails.Model.SectionModel] {
            
            guard let baseAssetResource = details.baseAsset,
                let baseAsset = baseAssetResource.id,
                let quoteAssetResource = details.quoteAsset,
                let quoteAsset = quoteAssetResource.id else {
                    return []
            }
            
            var sections: [Model.SectionModel] = []
            if details.orderBookId == 0 {
                let replacePrice = self.amountFormatter.assetAmountToString(details.price)
                let price = Localized(
                    .one_equals,
                    replace: [
                        .one_equals_replace_base_asset: baseAsset,
                        .one_equals_replace_quote_asset: quoteAsset,
                        .one_equals_replace_price: replacePrice
                    ]
                )
                let priceCell = Model.CellModel(
                    title: price,
                    hint: Localized(.price),
                    
                    identifier: .price
                )
                let dateCell = self.createDateCell(date: operation.appliedAt)
                let infoSection = Model.SectionModel(
                    title: "",
                    cells: [priceCell, dateCell],
                    description: ""
                )
                sections.append(infoSection)
                
                let baseAmountTitle = self.amountFormatter.formatAmount(
                    details.baseAmount,
                    currency: baseAsset
                )
                let toReceiveCell = Model.CellModel(
                    title: baseAmountTitle,
                    hint: Localized(.amount),
                    identifier: .amount,
                    isSeparatorHidden: true
                )
                let toReceiveSection = Model.SectionModel(
                    title: Localized(.to_receive),
                    cells: [toReceiveCell],
                    description: ""
                )
                sections.append(toReceiveSection)
                
            } else {
                let tokenCell = Model.CellModel(
                    title: baseAsset,
                    hint: Localized(.asset),
                    identifier: .token
                )
                let dateCell = self.createDateCell(date: operation.appliedAt)
                let infoSection = Model.SectionModel(
                    title: "",
                    cells: [tokenCell, dateCell],
                    description: ""
                )
                sections.append(infoSection)
            }
            
            let quoteAmount = details.baseAmount * details.price
            let quoteAmountTitle = self.amountFormatter.formatAmount(
                quoteAmount,
                currency: quoteAsset
            )
            let toPayCell = Model.CellModel(
                title: quoteAmountTitle,
                hint: Localized(.amount),
                identifier: .amount,
                isSeparatorHidden: true
            )
            let toPaySection = Model.SectionModel(
                title: Localized(.to_pay),
                cells: [toPayCell],
                description: ""
            )
            sections.insert(toPaySection, at: 1)
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
            var offerInfoCells: [TransactionDetails.Model.CellModel] = []
            let effectCell = TransactionDetails.Model.CellModel(
                title: Localized(.matched),
                hint: Localized(.effect),
                identifier: .matched
            )
            offerInfoCells.append(effectCell)
            
            if let priceCell = self.createPriceCell(
                details: details,
                matchedEffect: matchedEffect
                ) {
                
                offerInfoCells.append(priceCell)
            }
            
            let dateCell = self.createDateCell(date: operation.appliedAt)
            offerInfoCells.append(dateCell)
            
            let offerInfoSection = TransactionDetails.Model.SectionModel(
                title: "",
                cells: offerInfoCells,
                description: ""
            )
            sections.append(offerInfoSection)
            
            var chargedCells: [Model.CellModel] = []
            let chargedAmount = TransactionDetails.Model.Amount(
                value: charged.amount,
                asset: charged.assetCode
            )
            
            let chargedCell = TransactionDetails.Model.CellModel(
                title: self.amountFormatter.formatAmount(chargedAmount),
                hint: Localized(.amount),
                identifier: .amount,
                isSeparatorHidden: true
            )
            chargedCells.append(chargedCell)
            let chargedFeeAmount = charged.fee.calculatedPercent + charged.fee.fixed
            if chargedFeeAmount > 0 {
                if let index = chargedCells.indexOf(chargedCell) {
                    chargedCells[index].isSeparatorHidden = false
                }
                let chargedFee = Model.Amount(
                    value: chargedFeeAmount,
                    asset: charged.assetCode
                )
                let chargedFeeCell = TransactionDetails.Model.CellModel(
                    title: self.amountFormatter.formatAmount(chargedFee),
                    hint: Localized(.fee),
                    identifier: .fee
                )
                chargedCells.append(chargedFeeCell)
                
                let totalChargedFee = Model.Amount(
                    value: charged.amount + chargedFeeAmount,
                    asset: charged.assetCode
                )
                let totalChargedFeeCell = TransactionDetails.Model.CellModel(
                    title: self.amountFormatter.formatAmount(totalChargedFee),
                    hint: Localized(.total),
                    identifier: .total,
                    isSeparatorHidden: true
                )
                chargedCells.append(totalChargedFeeCell)
            }
            
            let chargedSection = TransactionDetails.Model.SectionModel(
                title: Localized(.charged),
                cells: chargedCells,
                description: ""
            )
            sections.append(chargedSection)
            
            var fundedCells: [Model.CellModel] = []
            let fundedAmount = TransactionDetails.Model.Amount(
                value: funded.amount,
                asset: funded.assetCode
            )
            
            let fundedCell = TransactionDetails.Model.CellModel(
                title: self.amountFormatter.formatAmount(fundedAmount),
                hint: Localized(.amount),
                identifier: .amount,
                isSeparatorHidden: true
            )
            fundedCells.append(fundedCell)
            let fundedFeeAmount = funded.fee.calculatedPercent + funded.fee.fixed
            if fundedFeeAmount > 0 {
                if let index = fundedCells.indexOf(fundedCell) {
                    fundedCells[index].isSeparatorHidden = false
                }
                let fundedFee = Model.Amount(
                    value: fundedFeeAmount,
                    asset: funded.assetCode
                )
                let fundedFeeCell = TransactionDetails.Model.CellModel(
                    title: self.amountFormatter.formatAmount(fundedFee),
                    hint: Localized(.fee),
                    identifier: .fee
                )
                fundedCells.append(fundedFeeCell)
                
                let totalFundedAmount = Model.Amount(
                    value: funded.amount - fundedFeeAmount,
                    asset: funded.assetCode
                )
                let totalFundedAmountCell = TransactionDetails.Model.CellModel(
                    title: self.amountFormatter.formatAmount(totalFundedAmount),
                    hint: Localized(.total),
                    identifier: .total,
                    isSeparatorHidden: true
                )
                fundedCells.append(totalFundedAmountCell)
            }
            
            let fundedSection = TransactionDetails.Model.SectionModel(
                title: Localized(.funded),
                cells: fundedCells,
                description: ""
            )
            sections.append(fundedSection)
            
            return sections
        }
        
        private func createDateCell(date: Date) -> TransactionDetails.Model.CellModel {
            let dateCell = TransactionDetails.Model.CellModel(
                title: self.dateFormatter.dateToString(date: date),
                hint: Localized(.date),
                identifier: .date,
                isSeparatorHidden: true
            )
            return dateCell
        }
        
        private func createDescriptionCells(
            details: OperationDetailsResource,
            balanceChangeEffect: EffectBalanceChangeResource
            ) -> [TransactionDetails.Model.CellModel] {
            
            var cells: [TransactionDetails.Model.CellModel] = []
            switch details.operationDetailsRelatedToBalance {
                
            case .opCreateWithdrawRequestDetails(let withdraw):
                guard let address = withdraw.creatorDetails["address"] as? String else {
                    return cells
                }
                let addressCell = TransactionDetails.Model.CellModel(
                    title: address,
                    hint: Localized(.destination_address),
                    identifier: .destination
                )
                cells.append(addressCell)
                
            case .opPaymentDetails(let payment):
                var emailCell: TransactionDetails.Model.CellModel?
                
                if balanceChangeEffect as? EffectChargedResource != nil,
                    let toAccount = payment.accountTo,
                    let toAccountId = toAccount.id {
                    
                    if self.counterpartyEmail == nil {
                        self.fetchEmail(accountId: toAccountId)
                    }
                    
                    let accountToCell = TransactionDetails.Model.CellModel(
                        title: toAccountId,
                        hint: Localized(.recipient),
                        identifier: .recipient
                    )
                    emailCell = TransactionDetails.Model.CellModel(
                        title: self.counterpartyEmail ?? Localized(.loading),
                        hint: Localized(.recipients_email),
                        identifier: .email
                    )
                    cells.append(accountToCell)
                } else if balanceChangeEffect as? EffectFundedResource != nil,
                    let fromAccount = payment.accountFrom,
                    let fromAccountId = fromAccount.id {
                    
                    if self.counterpartyEmail == nil {
                        self.fetchEmail(accountId: fromAccountId)
                    }
                    
                    let accountFromCell = TransactionDetails.Model.CellModel(
                        title: fromAccountId,
                        hint: Localized(.sender),
                        identifier: .sender
                    )
                    emailCell = TransactionDetails.Model.CellModel(
                        title: self.counterpartyEmail ?? Localized(.loading),
                        hint: Localized(.senders_email),
                        identifier: .email
                    )
                    cells.append(accountFromCell)
                }
                if let cell = emailCell {
                    cells.append(cell)
                }
                
            case .opCreateAMLAlertRequestDetails,
                 .opCreateAtomicSwapBidRequestDetails,
                 .opPayoutDetails,
                 .opCreateIssuanceRequestDetails,
                 .`self`:
                
                return cells
            }
            return cells
        }
        
        private func createTitleCell(
            balanceChangeEffect: EffectBalanceChangeResource
            ) -> TransactionDetails.Model.CellModel {
            
            var effectCellValue: String?
            var identifier: TransactionDetails.CellIdentifier?
            
            switch balanceChangeEffect.effectBalanceChangeType {
                
            case .effectCharged:
                effectCellValue = Localized(.charged)
                identifier = .charged
                
            case .effectChargedFromLocked:
                effectCellValue = Localized(.charged_from_lock)
                identifier = .charged
                
            case .effectFunded:
                effectCellValue = Localized(.funded)
                identifier = .received
                
            case .effectIssued:
                effectCellValue = Localized(.issued)
                identifier = .received
                
            case .effectLocked:
                effectCellValue = Localized(.locked)
                identifier = .locked
                
            case .effectUnlocked:
                effectCellValue = Localized(.unlocked)
                identifier = .unlocked
                
            case .effectWithdrawn:
                effectCellValue = Localized(.withdrawn)
                identifier = .locked
                
            case .`self`:
                break
            }
            
            let effectCell = TransactionDetails.Model.CellModel(
                title: effectCellValue ?? Localized(.unknown),
                hint: Localized(.effect),
                identifier: identifier ?? .unknown
            )
            
            return effectCell
        }
        
        private func createPriceCell(
            details: OperationDetailsResource,
            matchedEffect: EffectMatchedResource
            ) -> TransactionDetails.Model.CellModel? {
            
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
            
            let formattedPrice = "\(matchedEffect.price)"
            
            let priceCell = TransactionDetails.Model.CellModel.init(
                title: Localized(
                    .one_equals,
                    replace: [
                        .one_equals_replace_base_asset: baseAsset,
                        .one_equals_replace_quote_asset: quoteAsset,
                        .one_equals_replace_price: formattedPrice
                    ]
                ),
                hint: Localized(.price),
                identifier: .price
            )
            
            return priceCell
        }
        
        private func createPaymentFeeCell(
            details: OperationDetailsResource,
            balanceChangeEffect: EffectBalanceChangeResource
            ) -> [TransactionDetails.Model.CellModel] {
            
            var cells: [Model.CellModel] = []
            switch details.operationDetailsRelatedToBalance {
                
            case .opPaymentDetails(let resource):
                guard balanceChangeEffect as? EffectChargedResource != nil,
                    let assetResource = resource.asset,
                    let asset = assetResource.id,
                    let fee = balanceChangeEffect.fee,
                    fee.fixed + fee.calculatedPercent > 0 else {
                        return cells
                }
                let feeAmount = TransactionDetails.Model.Amount(
                    value: fee.fixed + fee.calculatedPercent,
                    asset: asset
                )
                
                let feeCell = TransactionDetails.Model.CellModel(
                    title: self.amountFormatter.formatAmount(feeAmount),
                    hint: Localized(.fee),
                    identifier: .fee,
                    isSeparatorHidden: true
                )
                cells.append(feeCell)
                let totalAmount = Model.Amount(
                    value: feeAmount.value + resource.amount,
                    asset: asset
                )
                let totalCell = TransactionDetails.Model.CellModel(
                    title: self.amountFormatter.formatAmount(totalAmount),
                    hint: Localized(.total),
                    identifier: .total
                )
                cells.append(totalCell)
                return cells
                
            case .`self`,
                 .opCreateIssuanceRequestDetails,
                 .opCreateAMLAlertRequestDetails,
                 .opCreateAtomicSwapBidRequestDetails,
                 .opCreateWithdrawRequestDetails,
                 .opPayoutDetails:
                
                break
            }
            
            return cells
        }
        
        private func createDetailsCells(
            details: OperationDetailsResource,
            balanceChangeEffect: EffectBalanceChangeResource
            ) -> [TransactionDetails.Model.CellModel] {
            
            var detailsCells: [TransactionDetails.Model.CellModel] = []
            
            switch details.operationDetailsRelatedToBalance {
                
            case .opCreateIssuanceRequestDetails(let resource):
                let referenceCell = TransactionDetails.Model.CellModel(
                    title: resource.reference,
                    hint: Localized(.reference),
                    identifier: .reference
                )
                detailsCells.append(referenceCell)
                
            case .opPaymentDetails(let resource):
                guard balanceChangeEffect as? EffectChargedResource != nil else {
                    return []
                }
                
                if resource.sourcePayForDestination {
                    let senderPaysCell = TransactionDetails.Model.CellModel(
                        title: Localized(.recipients_fee_has_been_paid),
                        hint: "",
                        identifier: .unknown
                    )
                    detailsCells.append(senderPaysCell)
                }
                
                if !resource.subject.isEmpty {
                    let subjectCell = TransactionDetails.Model.CellModel(
                        title: resource.subject,
                        hint: Localized(.description),
                        identifier: .reference
                    )
                    detailsCells.append(subjectCell)
                }
                
            case .`self`,
                 .opCreateAMLAlertRequestDetails,
                 .opCreateAtomicSwapBidRequestDetails,
                 .opCreateWithdrawRequestDetails,
                 .opPayoutDetails:
                
                break
            }
            
            return detailsCells
        }
        
        private func createManageAssetPairDetailsSection(
            details: OpManageAssetPairDetailsResource
            ) -> TransactionDetails.Model.SectionModel? {
            
            guard let baseAssetResource = details.baseAsset,
                let baseAsset = baseAssetResource.id,
                let quoteAssetResource = details.quoteAsset,
                let quoteAsset = quoteAssetResource.id else {
                    return nil
            }
            
            var cells: [TransactionDetails.Model.CellModel] = []
            
            let code = "\(quoteAsset)/\(baseAsset)"
            let codeCell = TransactionDetails.Model.CellModel(
                title: code,
                hint: Localized(.code),
                identifier: .code
            )
            cells.append(codeCell)
            
            let physicalPriceFormatted = "\(details.physicalPrice)"
            
            let physicalPrice = Localized(
                .one_equals,
                replace: [
                    .one_equals_replace_quote_asset: quoteAsset,
                    .one_equals_replace_price: physicalPriceFormatted,
                    .one_equals_replace_base_asset: baseAsset
                ]
            )
            
            let physicalPriceCell = TransactionDetails.Model.CellModel(
                title: physicalPrice,
                hint: Localized(.physical_price),
                identifier: .price
            )
            cells.append(physicalPriceCell)
            
            let tradable: String
            let restrictedByPhysical: String
            let restrictedByCurrent: String
            
            if let policy = details.policies {
                tradable = self.meetsPolicy(
                    policy: policy.value,
                    policyToCheck: .tradeableSecondaryMarket
                    ) ? Localized(.can_be_traded_on_secondary_market) :
                    Localized(.cannot_be_traded_on_secondary_market)
                
                restrictedByPhysical = self.meetsPolicy(
                    policy: policy.value,
                    policyToCheck: .physicalPriceRestriction
                    ) ? Localized(.is_restricted_by_physical_price) :
                    Localized(.is_not_restricted_by_physical_price)
                
                restrictedByCurrent = self.meetsPolicy(
                    policy: policy.value,
                    policyToCheck: .currentPriceRestriction
                    ) ? Localized(.is_restricted_by_current_price) :
                    Localized(.is_not_restricted_by_current_price)
            } else {
                tradable = Localized(.is_not_restricted_by_physical_price)
                restrictedByPhysical = Localized(.is_not_restricted_by_current_price)
                restrictedByCurrent = Localized(.cannot_be_traded_on_secondary_market)
            }
            
            let tradeMarketCell = TransactionDetails.Model.CellModel(
                title: tradable,
                hint: "",
                identifier: .check
            )
            
            let physicalPriceRestrictionCell = TransactionDetails.Model.CellModel(
                title: restrictedByPhysical,
                hint: "",
                identifier: .physicalPrice
            )
            
            let currentPriceRestrictionCell = TransactionDetails.Model.CellModel(
                title: restrictedByCurrent,
                hint: "",
                identifier: .currentPrice
            )
            
            cells.append(tradeMarketCell)
            cells.append(physicalPriceRestrictionCell)
            cells.append(currentPriceRestrictionCell)
            
            let section = Model.SectionModel(
                title: Localized(.asset_pair),
                cells: cells,
                description: ""
            )
            return section
        }
        
        private func meetsPolicy(policy: Int32, policyToCheck: AssetPairPolicy) -> Bool {
            return (policy & policyToCheck.rawValue) == policyToCheck.rawValue
        }
        
        private func fetchEmail(accountId: String) {
            self.emailFetcher.fetchEmail(
                accountId: accountId,
                completion: { [weak self] (result) in
                    switch result {
                        
                    case .failed:
                        return
                        
                    case .succeeded(let email):
                        self?.counterpartyEmail = email
                        self?.loadDataSections()
                    }
            })
        }
    }
}
// swiftlint:enable type_body_length

extension TransactionDetails.OperationSectionsProvider: TransactionDetails.SectionsProviderProtocol {
    
    func observeTransaction() -> Observable<[TransactionDetails.Model.SectionModel]> {
        self.transactionsProvider
            .observeParicipantEffects()
            .subscribe(onNext: { [weak self] (effects) in
                guard let effect = effects.first(where: { (effect) -> Bool in
                    guard let effectId = effect.id,
                        let effectIdUInt64 = UInt64(effectId),
                        let identifier = self?.identifier else {
                            return false
                    }
                    return identifier == effectIdUInt64
                }) else {
                    return
                }
                self?.effect = effect
                self?.loadDataSections()
            })
            .disposed(by: self.disposeBag)
        
        return self.sectionsRelay.asObservable()
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

extension TransactionDetails.OperationSectionsProvider {
    enum AssetPairPolicy: Int32 {
        case tradeableSecondaryMarket = 1
        case physicalPriceRestriction = 2
        case currentPriceRestriction = 4
    }
}
// swiftlint:enable file_length
