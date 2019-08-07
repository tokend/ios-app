import Foundation
import TokenDSDK
import TokenDWallet
import DLCryptoKit
import RxCocoa
import RxSwift

extension ConfirmationScene {
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
        private let amountPrecision: Int
        private let sectionsRelay: BehaviorRelay<[ConfirmationScene.Model.SectionModel]> = BehaviorRelay(value: [])
        private var payRecipientFeeCellState: Bool = true
        private var descriptionCellText: String = ""
        
        // MARK: -
        
        init(
            sendPaymentModel: Model.SendPaymentModel,
            transactionSender: TransactionSender,
            networkInfoFetcher: NetworkInfoFetcher,
            amountFormatter: AmountFormatterProtocol,
            userDataProvider: UserDataProviderProtocol,
            amountConverter: AmountConverterProtocol,
            percentFormatter: PercentFormatterProtocol,
            amountPrecision: Int
            ) {
            self.sendPaymentModel = sendPaymentModel
            self.transactionSender = transactionSender
            self.networkInfoFetcher = networkInfoFetcher
            self.userDataProvider = userDataProvider
            self.amountFormatter = amountFormatter
            self.amountConverter = amountConverter
            self.amountPrecision = amountPrecision
            self.percentFormatter = percentFormatter
        }
        
        // MARK: - Private
        
        private func confirmationSendPayment(
            networkInfo: NetworkInfoModel,
            completion: @escaping (ConfirmationResult) -> Void
            ) {
            
            let sourceFee = self.createFee(feeModel: self.sendPaymentModel.senderFee)
            let destinationFee = self.createFee(feeModel: self.sendPaymentModel.recipientFee)
            
            let feeData = PaymentFeeDataV2(
                sourceFee: sourceFee,
                destinationFee: destinationFee,
                sourcePaysForDest: self.payRecipientFeeCellState,
                ext: .emptyVersion()
            )
            
            let amount = self.amountConverter.convertDecimalToUInt64(
                value: self.sendPaymentModel.amount,
                precision: self.amountPrecision
            )
            
            guard let sourceBalanceID = BalanceID(
                base32EncodedString: self.sendPaymentModel.senderBalanceId,
                expectedVersion: .balanceIdEd25519
                ) else {
                    completion(.failed(.failedToDecodeBalanceId("senderBalanceId")))
                    return
            }
            
            guard let destinationAccountID = AccountID(
                base32EncodedString: self.sendPaymentModel.recipientAccountId,
                expectedVersion: .accountIdEd25519
                ) else {
                    completion(.failed(.failedToDecodeAccountId("recipientAccountId")))
                    return
            }
            
            let operation = PaymentOpV2(
                sourceBalanceID: sourceBalanceID,
                destination: .account(destinationAccountID),
                amount: amount,
                feeData: feeData,
                subject: self.descriptionCellText,
                reference: "",
                ext: .emptyVersion()
            )
            
            let transactionBuilder: TransactionBuilder = TransactionBuilder(
                networkParams: networkInfo.networkParams,
                sourceAccountId: self.userDataProvider.accountId,
                params: networkInfo.getTxBuilderParams(sendDate: Date())
            )
            
            transactionBuilder.add(
                operationBody: .paymentV2(operation),
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
        
        private func createFee(feeModel: Model.FeeModel) -> FeeDataV2 {
            let maxPaymentFeeDecimal = feeModel.fixed + feeModel.percent
            
            let maxPaymentFee = self.amountConverter.convertDecimalToUInt64(
                value: maxPaymentFeeDecimal,
                precision: self.amountPrecision
            )
            let fixedFee = self.amountConverter.convertDecimalToUInt64(
                value: feeModel.fixed,
                precision: self.amountPrecision
            )
            
            let destinationFee = FeeDataV2(
                maxPaymentFee: maxPaymentFee,
                fixedFee: fixedFee,
                feeAsset: feeModel.asset,
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
        let recipientCell = ConfirmationScene.Model.CellModel(
            title: "Recipient",
            cellType: .text(value: self.sendPaymentModel.recipientAccountId),
            identifier: "recipientCell"
        )
        let recipientSection = ConfirmationScene.Model.SectionModel(cells: [recipientCell])
        
        let amountCellText = self.amountFormatter.assetAmountToString(
            self.sendPaymentModel.amount
            ) + " " + self.sendPaymentModel.asset
        
        let amountCell = ConfirmationScene.Model.CellModel(
            title: "Amount",
            cellType: .text(value: amountCellText),
            identifier: "amountCell"
        )
        
        let feeCellText = self.amountFormatter.assetAmountToString(
            self.sendPaymentModel.senderFee.fixed
            ) + " " + self.sendPaymentModel.senderFee.asset
        
        let feeCell = ConfirmationScene.Model.CellModel(
            title: "Fee",
            cellType: .text(value: feeCellText),
            identifier: "feeCell"
        )
        
        let recipientFeeCellText = self.percentFormatter.percentToString(
            value: self.sendPaymentModel.recipientFee.fixed
            ) + " " + self.sendPaymentModel.recipientFee.asset
        
        let recipientFeeCell = ConfirmationScene.Model.CellModel(
            title: "Recipient's fee",
            cellType: .text(value: recipientFeeCellText),
            identifier: "recipientFeeCell"
        )
        
        let payRecipientFeeCell = ConfirmationScene.Model.CellModel(
            title: "Pay recipient's fee",
            cellType: .boolSwitch(value: self.payRecipientFeeCellState),
            identifier: "payRecipientFeeCell"
        )
        
        let descriptionCell = ConfirmationScene.Model.CellModel(
            title: "Description",
            cellType: .textField(
                value: self.descriptionCellText,
                placeholder: "Description(optional)", maxCharacters: 100
            ),
            identifier: "descriptionCell"
        )
        
        let amountSection = ConfirmationScene.Model.SectionModel(
            cells: [
                amountCell,
                feeCell,
                recipientFeeCell,
                payRecipientFeeCell,
                descriptionCell
            ]
        )
        
        self.sectionsRelay.accept([
            recipientSection,
            amountSection
            ]
        )
    }
    
    func handleTextEdit(
        identifier: ConfirmationScene.CellIdentifier,
        value: String?
        ) {
        if identifier == "descriptionCell" {
            self.descriptionCellText = value ?? ""
        }
    }
    
    func handleBoolSwitch(
        identifier: ConfirmationScene.CellIdentifier,
        value: Bool
        ) {
        if identifier == "payRecipientFeeCell" {
            self.payRecipientFeeCellState = value
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
