import Foundation
import TokenDSDK
import TokenDWallet
import DLCryptoKit
import RxCocoa
import RxSwift

extension ConfirmationScene {
    
    typealias Fee = TokenDWallet.Fee
    
    class SendPaymentConfirmationSectionsProvider {
        
        private struct DestinationAddress: Encodable {
            let address: String
        }
        
        // MARK: - Private properties
        
        private let sendPaymentModel: Model.SendPaymentModel
        private let transactionSender: TransactionSender
        private let networkInfoFetcher: NetworkInfoFetcher
        private let userDataProvider: UserDataProviderProtocol
        private let amountFormatter: AmountFormatterProtocol
        private let percentFormatter: PercentFormatterProtocol
        private let amountConverter: AmountConverterProtocol
        private let sectionsRelay: BehaviorRelay<[ConfirmationScene.Model.SectionModel]> = BehaviorRelay(value: [])
        private var payRecipientFeeCellState: Bool = true
        
        // MARK: -
        
        init(
            sendPaymentModel: Model.SendPaymentModel,
            transactionSender: TransactionSender,
            networkInfoFetcher: NetworkInfoFetcher,
            amountFormatter: AmountFormatterProtocol,
            userDataProvider: UserDataProviderProtocol,
            amountConverter: AmountConverterProtocol,
            percentFormatter: PercentFormatterProtocol
            ) {
            self.sendPaymentModel = sendPaymentModel
            self.transactionSender = transactionSender
            self.networkInfoFetcher = networkInfoFetcher
            self.userDataProvider = userDataProvider
            self.amountFormatter = amountFormatter
            self.amountConverter = amountConverter
            self.percentFormatter = percentFormatter
        }
        
        // MARK: - Private
        
        private func confirmationSendPayment(
            networkInfo: NetworkInfoModel,
            completion: @escaping (ConfirmationResult) -> Void
            ) {
            
            let sourceFee = self.createFee(
                feeModel: self.sendPaymentModel.senderFee,
                networkInfo: networkInfo
            )
            let destinationFee = self.createFee(
                feeModel: self.sendPaymentModel.recipientFee,
                networkInfo: networkInfo
            )
            
            let feeData = PaymentFeeData(
                sourceFee: sourceFee,
                destinationFee: destinationFee,
                sourcePaysForDest: self.payRecipientFeeCellState,
                ext: .emptyVersion()
            )
            
            let amount = self.amountConverter.convertDecimalToUInt64(
                value: self.sendPaymentModel.amount,
                precision: networkInfo.precision
            )
            
            guard let sourceBalanceID = BalanceID(
                base32EncodedString: self.sendPaymentModel.senderBalanceId,
                expectedVersion: .balanceIdEd25519
                ) else {
                    completion(.failed(.failedToDecodeBalanceId(.senderBalanceId)))
                    return
            }
            
            guard let destinationAccountID = AccountID(
                base32EncodedString: self.sendPaymentModel.recipientAccountId,
                expectedVersion: .accountIdEd25519
                ) else {
                    completion(.failed(.failedToDecodeAccountId(.recipientAccountId)))
                    return
            }
            
            let operation = PaymentOp(
                sourceBalanceID: sourceBalanceID,
                destination: .account(destinationAccountID),
                amount: amount,
                feeData: feeData,
                subject: self.sendPaymentModel.description,
                reference: self.sendPaymentModel.reference,
                ext: .emptyVersion()
            )
            
            let transactionBuilder: TransactionBuilder = TransactionBuilder(
                networkParams: networkInfo.networkParams,
                sourceAccountId: self.userDataProvider.accountId,
                params: networkInfo.getTxBuilderParams(sendDate: Date())
            )
            
            transactionBuilder.add(
                operationBody: .payment(operation),
                operationSourceAccount: self.userDataProvider.accountId
            )
            do {
                let transaction = try transactionBuilder.buildTransaction()
                
                try self.transactionSender.sendTransaction(
                    transaction,
                    walletId: self.userDataProvider.walletId
                ) { (result) in
                    switch result {
                    case .succeeded:
                        completion(.succeeded)
                    case .failed(let error):
                        completion(.failed(.sendTransactionError(error)))
                    }
                }
            } catch let error {
                completion(.failed(.sendTransactionError(error)))
            }
        }
        
        private func createFee(feeModel: Model.FeeModel, networkInfo: NetworkInfoModel) -> Fee {
            let fixedFee = self.amountConverter.convertDecimalToUInt64(
                value: feeModel.fixed,
                precision: networkInfo.precision
            )
            
            let percent = self.amountConverter.convertDecimalToUInt64(
                value: feeModel.percent ,
                precision: networkInfo.precision
            )
            
            let destinationFee = Fee(
                fixed: fixedFee,
                percent: percent,
                ext: .emptyVersion()
            )
            return destinationFee
        }
    }
}

extension ConfirmationScene.SendPaymentConfirmationSectionsProvider: ConfirmationScene.SectionsProvider {
    func observeConfirmationSections() -> Observable<[ConfirmationScene.Model.SectionModel]> {
        return self.sectionsRelay.asObservable()
    }
    
    func loadConfirmationSections() {
        var sections: [ConfirmationScene.Model.SectionModel] = []
        var destinationCells: [ConfirmationScene.Model.CellModel] = []
        let recipientCell = ConfirmationScene.Model.CellModel(
            hint: Localized(.recipient),
            cellType: .text(value: self.sendPaymentModel.recipientAccountId),
            identifier: .recipient
        )
        destinationCells.append(recipientCell)
        
        if !self.sendPaymentModel.description.isEmpty {
            let descriptionCell = ConfirmationScene.Model.CellModel(
                hint: Localized(.description),
                cellType: .text(value: self.sendPaymentModel.description),
                identifier: .description
            )
            destinationCells.append(descriptionCell)
        }
        let destinationSection = ConfirmationScene.Model.SectionModel(
            title: "",
            cells: destinationCells
        )
        sections.append(destinationSection)
        
        var toPayCells: [ConfirmationScene.Model.CellModel] = []
        let amountCellText = self.amountFormatter.assetAmountToString(
            self.sendPaymentModel.amount
            ) + " " + self.sendPaymentModel.asset
        
        let amountCell = ConfirmationScene.Model.CellModel(
            hint: Localized(.amount),
            cellType: .text(value: amountCellText),
            identifier: .amount
        )
        toPayCells.append(amountCell)
        
        var senderFeeAmount = self.sendPaymentModel.senderFee.fixed + self.sendPaymentModel.senderFee.percent
        if self.payRecipientFeeCellState {
            senderFeeAmount += self.sendPaymentModel.recipientFee.fixed + self.sendPaymentModel.recipientFee.percent
        }
        
        if senderFeeAmount > 0 {
            let formattedAmount = self.amountFormatter.assetAmountToString(senderFeeAmount)
            let feeCellText = formattedAmount + " " + self.sendPaymentModel.senderFee.asset
            
            let feeCell = ConfirmationScene.Model.CellModel(
                hint: Localized(.fee),
                cellType: .text(value: feeCellText),
                identifier: .fee
            )
            
            let totalAmount = self.sendPaymentModel.amount + senderFeeAmount
            let formattedTotalAmount = self.amountFormatter.assetAmountToString(totalAmount)
            let totalAmountCellText = formattedTotalAmount + " " + self.sendPaymentModel.senderFee.asset
            
            let totalCell = ConfirmationScene.Model.CellModel(
                hint: Localized(.total),
                cellType: .text(value: totalAmountCellText),
                identifier: .total
            )
            toPayCells.append(feeCell)
            toPayCells.append(totalCell)
        }
        let toPaySection = ConfirmationScene.Model.SectionModel(
            title: Localized(.to_pay),
            cells: toPayCells
        )
        sections.append(toPaySection)
        
        var toReceiveCells: [ConfirmationScene.Model.CellModel] = []
        let toReceiveAmountCellText = self.amountFormatter.assetAmountToString(
            self.sendPaymentModel.amount
            ) + " " + self.sendPaymentModel.asset
        
        let toReceiveAmountCell = ConfirmationScene.Model.CellModel(
            hint: Localized(.amount),
            cellType: .text(value: toReceiveAmountCellText),
            identifier: .amount
        )
        toReceiveCells.append(toReceiveAmountCell)
        
        let recepientFeeAmount = self.sendPaymentModel.recipientFee.fixed + self.sendPaymentModel.recipientFee.percent
        
        if recepientFeeAmount > 0 {
            let formattedAmount = self.amountFormatter.assetAmountToString(recepientFeeAmount)
            let feeCellText = formattedAmount + " " + self.sendPaymentModel.senderFee.asset
            
            let feeCell = ConfirmationScene.Model.CellModel(
                hint: Localized(.fee),
                cellType: .text(value: feeCellText),
                identifier: .fee,
                isDisabled: self.payRecipientFeeCellState
            )
            
            var totalAmount = self.sendPaymentModel.amount
            if !self.payRecipientFeeCellState {
                totalAmount -= self.sendPaymentModel.recipientFee.fixed + self.sendPaymentModel.recipientFee.percent
            }
            totalAmount = totalAmount > 0 ? totalAmount : 0
            let formattedTotalAmount = self.amountFormatter.assetAmountToString(totalAmount)
            let totalAmountCellText = formattedTotalAmount + " " + self.sendPaymentModel.senderFee.asset
            
            let totalCell = ConfirmationScene.Model.CellModel(
                hint: Localized(.total),
                cellType: .text(value: totalAmountCellText),
                identifier: .total
            )
            let payRecipientFeeCell = ConfirmationScene.Model.CellModel(
                hint: Localized(.pay_recipients_fee),
                cellType: .boolSwitch(value: self.payRecipientFeeCellState),
                identifier: .payRecipientFee
            )
            toReceiveCells.append(feeCell)
            toReceiveCells.append(totalCell)
            toReceiveCells.append(payRecipientFeeCell)
        }
        let toReceiveSection = ConfirmationScene.Model.SectionModel(
            title: Localized(.to_receive),
            cells: toReceiveCells
        )
        sections.append(toReceiveSection)
        
        self.sectionsRelay.accept(sections)
    }
    
    func handleTextEdit(
        identifier: ConfirmationScene.CellIdentifier,
        value: String?
        ) {
        
    }
    
    func handleBoolSwitch(
        identifier: ConfirmationScene.CellIdentifier,
        value: Bool
        ) {
        
        if identifier == .payRecipientFee {
            self.payRecipientFeeCellState = value
            self.loadConfirmationSections()
        }
    }
    
    func handleConfirmAction(completion: @escaping (_ result: ConfirmationResult) -> Void) {
        self.networkInfoFetcher.fetchNetworkInfo { [weak self] (result) in
            switch result {
                
            case .failed(let error):
                completion(.failed(.networkInfoError(error)))
                
            case .succeeded(let networkInfo):
                self?.confirmationSendPayment(
                    networkInfo: networkInfo,
                    completion: completion
                )
            }
        }
    }
}
