import UIKit
import RxCocoa
import RxSwift
import TokenDSDK

extension TransactionDetails {
    class OperationSectionsProvider {
        
        private let transactionsRepo: TransactionsRepo
        private let identifier: UInt64
        private let accountId: String
        
        private let dateFormatter = TransactionDetails.DateFormatter()
        private let amountFormatter = TransactionDetails.AmountFormatter()
        
        init(
            transactionsRepo: TransactionsRepo,
            identifier: UInt64,
            accountId: String
            ) {
            
            self.transactionsRepo = transactionsRepo
            self.identifier = identifier
            self.accountId = accountId
        }
        
        // MARK: - Private
        
        private func createDateSection(date: Date) -> TransactionDetails.Model.SectionModel {
            let dateCell = TransactionDetails.Model.CellModel(
                title: self.dateFormatter.dateToString(date: date),
                value: "",
                identifier: "dateCell"
            )
            let dateSection = TransactionDetails.Model.SectionModel(
                title: "Date",
                cells: [dateCell],
                description: ""
            )
            return dateSection
        }
        
        private func loadDataSections(
            operation: TransactionsRepo.Operation
            ) -> [TransactionDetails.Model.SectionModel] {
            
            if let payment = operation.base as? PaymentOperationResponse {
                return self.sectionsForPayment(payment, accountId: self.accountId)
            } else if let payment = operation.base as? PaymentV2OperationResponse {
                return self.sectionsForPaymentV2(payment, accountId: self.accountId)
            } else if let withdraw = operation.base as? CreateWithdrawalRequest {
                return self.sectionsForWithdraw(withdraw)
            } else if let checkSaleState = operation as? TransactionsRepo.CheckSaleStateOperation {
                return self.sectionsForCheckSaleState(checkSaleState)
            } else if let manageOffer = operation as? TransactionsRepo.ManageOfferOperation {
                return self.sectionsForManageOffer(manageOffer)
            } else if let createIssuance = operation.base as? CreateIssuanceRequestResponse {
                return self.sectionsForCreateIssuanceRequest(createIssuance)
            }
            return []
        }
        
        private func sectionsForPayment(
            _ payment: PaymentOperationResponse,
            accountId: String
            ) -> [TransactionDetails.Model.SectionModel] {
            
            var sections: [TransactionDetails.Model.SectionModel] = []
            var amountCells: [TransactionDetails.Model.CellModel] = []
            
            let recipientCellTitle: String
            let recipientCellValue: String
            
            let isSent = accountId == payment.fromAccountId
            
            if isSent {
                recipientCellTitle = "Recipient"
                recipientCellValue = payment.toAccountId
            } else {
                recipientCellTitle = "Sender"
                recipientCellValue = payment.fromAccountId
            }
            
            let recipientCell = TransactionDetails.Model.CellModel(
                title: recipientCellTitle,
                value: recipientCellValue,
                identifier: "recipientCell"
            )
            
            let recipientSection = TransactionDetails.Model.SectionModel(
                title: "",
                cells: [recipientCell],
                description: ""
            )
            sections.append(recipientSection)
            
            let amount: Model.Amount = Model.Amount(value: payment.amount, asset: payment.asset)
            let amountCell = TransactionDetails.Model.CellModel(
                title: "Amount",
                value: self.amountFormatter.formatAmount(amount),
                identifier: "amountCell"
            )
            amountCells.append(amountCell)
            
            let fee: Model.Amount
            if isSent {
                fee = Model.Amount(
                    value: payment.sourceFixedFee + payment.sourcePaymentFee,
                    asset: payment.asset
                )
            } else {
                fee = Model.Amount(
                    value: payment.destinationFixedFee + payment.destinationPaymentFee,
                    asset: payment.asset
                )
            }
            
            let feeCell = TransactionDetails.Model.CellModel(
                title: "Fee",
                value: self.amountFormatter.formatAmount(fee),
                identifier: "feeCell"
            )
            amountCells.append(feeCell)
            
            let feeFromSource = payment.sourcePaysForDest
            
            let recipientFeeIsPaidByMe: Bool = isSent && feeFromSource
            if recipientFeeIsPaidByMe {
                let recipientFee = Model.Amount(
                    value: payment.destinationFixedFee + payment.destinationPaymentFee,
                    asset: payment.asset
                )
                let feePecipientCell = TransactionDetails.Model.CellModel(
                    title: "Recipient's fee",
                    value: self.amountFormatter.formatAmount(recipientFee),
                    identifier: "feePecipientCell"
                )
                amountCells.append(feePecipientCell)
            }
            
            let amountSection = TransactionDetails.Model.SectionModel(
                title: "",
                cells: amountCells,
                description: ""
            )
            sections.append(amountSection)
            
            if let subject = payment.subject, subject != "" {
                let subjectCell = TransactionDetails.Model.CellModel(
                    title: subject,
                    value: "",
                    identifier: "subjectCell"
                )
                
                let subjectSection = TransactionDetails.Model.SectionModel(
                    title: "Description",
                    cells: [subjectCell],
                    description: ""
                )
                sections.append(subjectSection)
            }
            
            let dateSection = self.createDateSection(date: payment.ledgerCloseTime)
            sections.append(dateSection)
            
            return sections
        }
        
        private func sectionsForPaymentV2(
            _ payment: PaymentV2OperationResponse,
            accountId: String
            ) -> [TransactionDetails.Model.SectionModel] {
            
            var sections: [TransactionDetails.Model.SectionModel] = []
            
            let recipientCellTitle: String
            let recipientCellValue: String
            
            let isSent = accountId == payment.fromAccountId
            
            if isSent {
                recipientCellTitle = "Recipient"
                recipientCellValue = payment.toAccountId
            } else {
                recipientCellTitle = "Sender"
                recipientCellValue = payment.fromAccountId
            }
            
            let recipientCell = TransactionDetails.Model.CellModel(
                title: recipientCellTitle,
                value: recipientCellValue,
                identifier: "recipientCell"
            )
            
            let recipientSection = TransactionDetails.Model.SectionModel(
                title: "",
                cells: [recipientCell],
                description: ""
            )
            sections.append(recipientSection)
            
            var amountCells: [Model.CellModel] = []
            
            let amount: Model.Amount = Model.Amount(value: payment.amount, asset: payment.asset)
            
            let amountCell = TransactionDetails.Model.CellModel(
                title: "Amount",
                value: self.amountFormatter.formatAmount(amount),
                identifier: "amountCell"
            )
            amountCells.append(amountCell)
            
            let fee: Model.Amount
            if isSent {
                let value = payment.sourceFeeData.fixedFee + payment.sourceFeeData.actualPaymentFee
                fee = Model.Amount(
                    value: value,
                    asset: payment.sourceFeeData.actualPaymentFeeAssetCode
                )
            } else {
                let value = payment.destinationFeeData.fixedFee + payment.destinationFeeData.actualPaymentFee
                fee = Model.Amount(
                    value: value,
                    asset: payment.destinationFeeData.actualPaymentFeeAssetCode
                )
            }
            
            let feeCell = TransactionDetails.Model.CellModel(
                title: "Fee",
                value: self.amountFormatter.formatAmount(fee),
                identifier: "feeCell"
            )
            amountCells.append(feeCell)
            
            let feeFromSource = payment.sourcePaysForDest
            
            let recipientFeeIsPaidByMe: Bool = isSent && feeFromSource
            if recipientFeeIsPaidByMe {
                let recipientFee = Model.Amount(
                    value: payment.destinationFeeData.fixedFee + payment.destinationFeeData.actualPaymentFee,
                    asset: payment.destinationFeeData.actualPaymentFeeAssetCode
                )
                let feePecipientCell = TransactionDetails.Model.CellModel(
                    title: "Recipient's fee",
                    value: self.amountFormatter.formatAmount(recipientFee),
                    identifier: "feePecipientCell"
                )
                amountCells.append(feePecipientCell)
            }
            
            let receivedSection = TransactionDetails.Model.SectionModel(
                title: "",
                cells: amountCells,
                description: ""
            )
            sections.append(receivedSection)
            
            if let subject = payment.subject, subject != "" {
                let subjectCell = TransactionDetails.Model.CellModel(
                    title: subject,
                    value: "",
                    identifier: "subjectCell"
                )
                
                let subjectSection = TransactionDetails.Model.SectionModel(
                    title: "Description",
                    cells: [subjectCell],
                    description: ""
                )
                sections.append(subjectSection)
            }
            
            let dateSection = self.createDateSection(date: payment.ledgerCloseTime)
            sections.append(dateSection)
            
            return sections
        }
        
        private func sectionsForWithdraw(
            _ withdraw: CreateWithdrawalRequest
            ) -> [TransactionDetails.Model.SectionModel] {
            
            let withdrawStateText: String
            switch withdraw.stateValue {
            case .canceled:
                withdrawStateText = "Canceled"
            case .failed:
                withdrawStateText = "Failed"
            case .pending:
                withdrawStateText = "Pending"
            case .rejected:
                withdrawStateText = "Rejected"
            case .success:
                withdrawStateText = "Success"
            }
            
            let stateCell = TransactionDetails.Model.CellModel(
                title: withdrawStateText,
                value: "",
                identifier: "stateCell"
            )
            
            let stateSection = TransactionDetails.Model.SectionModel(
                title: "State",
                cells: [stateCell],
                description: ""
            )
            
            let destinationText: String
            if let details = withdraw.externalDetails {
                destinationText = details.address
            } else {
                destinationText = "Unknown"
            }
            
            let destinationCell = TransactionDetails.Model.CellModel(
                title: destinationText,
                value: "",
                identifier: "destinationCell"
            )
            
            let destinationSection = TransactionDetails.Model.SectionModel(
                title: "Destination address",
                cells: [destinationCell],
                description: ""
            )
            
            let paid = withdraw.amount + withdraw.feeFixed
            let paidCell = TransactionDetails.Model.CellModel(
                title: "Paid",
                value: self.amountFormatter.formatAmount(Model.Amount(
                    value: paid,
                    asset: withdraw.destAsset
                )),
                identifier: "paidCell"
            )
            
            let amountSentCell = TransactionDetails.Model.CellModel(
                title: "Amount sent",
                value: self.amountFormatter.formatAmount(Model.Amount(
                    value: withdraw.amount,
                    asset: withdraw.destAsset
                )),
                identifier: "amountSentCell"
            )
            
            let fixedFeeCell = TransactionDetails.Model.CellModel(
                title: "Fixed fee",
                value: self.amountFormatter.formatAmount(Model.Amount(
                    value: withdraw.feeFixed,
                    asset: withdraw.destAsset
                )),
                identifier: "fixedFeeCell"
            )
            
            let percentFeeCell = TransactionDetails.Model.CellModel(
                title: "Percent fee",
                value: self.amountFormatter.formatAmount(Model.Amount(
                    value: withdraw.feePercent,
                    asset: withdraw.destAsset
                )),
                identifier: "percentFeeCell"
            )
            
            let paidSection = TransactionDetails.Model.SectionModel(
                title: "",
                cells: [paidCell, amountSentCell, fixedFeeCell, percentFeeCell],
                description: ""
            )
            
            let sentCell = TransactionDetails.Model.CellModel(
                title: "Sent",
                value: self.amountFormatter.formatAmount(Model.Amount(
                    value: withdraw.destAmount,
                    asset: withdraw.destAsset
                )),
                identifier: "sentCell"
            )
            
            let warningCell = TransactionDetails.Model.CellModel(
                title: "Received amount may be lower due to \(withdraw.destAsset) network fees",
                value: "",
                identifier: "warningCell"
            )
            
            let sentSection = TransactionDetails.Model.SectionModel(
                title: "",
                cells: [sentCell, warningCell],
                description: ""
            )
            
            let dateSection = self.createDateSection(date: withdraw.ledgerCloseTime)
            
            return [
                stateSection,
                destinationSection,
                paidSection,
                sentSection,
                dateSection
            ]
        }
        
        private func sectionsForCheckSaleState(
            _ checkSaleState: TransactionsRepo.CheckSaleStateOperation
            ) -> [TransactionDetails.Model.SectionModel] {
            
            let paid = checkSaleState.amount + checkSaleState.feeAmount
            let paidCell = TransactionDetails.Model.CellModel(
                title: "Paid",
                value: self.amountFormatter.formatAmount(Model.Amount(
                    value: paid,
                    asset: checkSaleState.asset
                )),
                identifier: "paidCell"
            )
            
            let amountSentCell = TransactionDetails.Model.CellModel(
                title: "Amount",
                value: self.amountFormatter.formatAmount(Model.Amount(
                    value: checkSaleState.amount,
                    asset: checkSaleState.asset
                )),
                identifier: "amountSentCell"
            )
            
            let fixedFeeCell = TransactionDetails.Model.CellModel(
                title: "Fixed fee",
                value: self.amountFormatter.formatAmount(Model.Amount(
                    value: checkSaleState.feeAmount,
                    asset: checkSaleState.feeAsset
                )),
                identifier: "fixedFeeCell"
            )
            
            let paidSection = TransactionDetails.Model.SectionModel(
                title: "",
                cells: [paidCell, amountSentCell, fixedFeeCell],
                description: ""
            )
            
            let receivedCell = TransactionDetails.Model.CellModel(
                title: "Received",
                value: self.amountFormatter.formatAmount(Model.Amount(
                    value: checkSaleState.match.quoteAmount,
                    asset: checkSaleState.match.quoteAsset
                )),
                identifier: "receivedCell"
            )
            
            let priceCell = TransactionDetails.Model.CellModel(
                title: "Price",
                value: self.amountFormatter.formatAmount(Model.Amount(
                    value: checkSaleState.match.price,
                    asset: checkSaleState.asset
                )),
                identifier: "priceCell"
            )
            
            let receivedSection = Model.SectionModel(
                title: "",
                cells: [receivedCell, priceCell],
                description: ""
            )
            
            let dateSection = self.createDateSection(date: checkSaleState.ledgerCloseTime)
            
            return [
                paidSection,
                receivedSection,
                dateSection
            ]
        }
        
        private func sectionsForManageOffer(
            _ manageOffer: TransactionsRepo.ManageOfferOperation
            ) -> [TransactionDetails.Model.SectionModel] {
            
            return self.sectionsForCheckSaleState(manageOffer)
        }
        
        private func sectionsForCreateIssuanceRequest(
            _ createIssuance: CreateIssuanceRequestResponse
            ) -> [TransactionDetails.Model.SectionModel] {
            
            let amount: Model.Amount = Model.Amount(value: createIssuance.amount, asset: createIssuance.asset)
            
            let amountCell = TransactionDetails.Model.CellModel(
                title: "Amount",
                value: amountFormatter.formatAmount(amount),
                identifier: "amountCell"
            )
            let receivedSection = TransactionDetails.Model.SectionModel(
                title: "Received",
                cells: [amountCell],
                description: ""
            )
            
            let investCell = TransactionDetails.Model.CellModel(
                title: createIssuance.reference,
                value: "",
                identifier: "investCell"
            )
            let referenceSection = TransactionDetails.Model.SectionModel(
                title: "Reference",
                cells: [investCell],
                description: ""
            )
            
            let dateSection = self.createDateSection(date: createIssuance.ledgerCloseTime)
            
            return [
                receivedSection,
                referenceSection,
                dateSection
            ]
        }
    }
}

extension TransactionDetails.OperationSectionsProvider: TransactionDetails.SectionsProviderProtocol {
    
    func observeTransaction() -> Observable<[TransactionDetails.Model.SectionModel]> {
        
        return self.transactionsRepo
            .observeOperations()
            .map { [weak self] (operations) -> [TransactionDetails.Model.SectionModel] in
                guard let operation = operations.first(where: { [weak self] (operation) -> Bool in
                    return operation.id == self?.identifier
                }) else {
                    return []
                }
                return self?.loadDataSections(operation: operation) ?? []
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
