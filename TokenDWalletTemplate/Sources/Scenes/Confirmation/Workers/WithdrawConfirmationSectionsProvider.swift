import Foundation
import TokenDSDK
import TokenDWallet
import DLCryptoKit
import RxCocoa
import RxSwift

extension ConfirmationScene {
    class WithdrawConfirmationSectionsProvider {
        
        private struct DestinationAddress: Encodable {
            let address: String
        }
        
        // MARK: - Private properties
        
        private let withdrawModel: Model.WithdrawModel
        private let transactionSender: TransactionSender
        private let networkInfoFetcher: NetworkInfoFetcher
        private let userDataProvider: UserDataProviderProtocol
        private let amountFormatter: AmountFormatterProtocol
        private let percentFormatter: PercentFormatterProtocol
        private let amountConverter: AmountConverterProtocol
        private let sectionsRelay: BehaviorRelay<[ConfirmationScene.Model.SectionModel]> = BehaviorRelay(value: [])
        
        // MARK: -
        
        init(
            withdrawModel: Model.WithdrawModel,
            transactionSender: TransactionSender,
            networkInfoFetcher: NetworkInfoFetcher,
            amountFormatter: AmountFormatterProtocol,
            userDataProvider: UserDataProviderProtocol,
            amountConverter: AmountConverterProtocol,
            percentFormatter: PercentFormatterProtocol
            ) {
            
            self.withdrawModel = withdrawModel
            self.transactionSender = transactionSender
            self.networkInfoFetcher = networkInfoFetcher
            self.userDataProvider = userDataProvider
            self.amountFormatter = amountFormatter
            self.amountConverter = amountConverter
            self.percentFormatter = percentFormatter
        }
        
        // MARK: - Private
        
        private func confirmationWithdrawal(
            networkInfo: NetworkInfoModel,
            completion: @escaping (ConfirmationResult) -> Void
            ) {
            
            let destinationAddressModel = DestinationAddress(address: self.withdrawModel.recipientAddress)
            
            guard let destinationAddressData = try? destinationAddressModel.encode(),
                let destAddress = String(data: destinationAddressData, encoding: .utf8)
                else {
                    completion(.failed(.failedToEncodeDestinationAddress))
                    return
            }
            
            let xdrAmount: Uint64 = self.amountConverter.convertDecimalToUInt64(
                value: self.withdrawModel.amount,
                precision: networkInfo.precision
            )
            
            let fee = Fee(
                fixed: 0,
                percent: 0,
                ext: .emptyVersion()
            )
            
            guard let balance = BalanceID(
                base32EncodedString: self.withdrawModel.senderBalanceId,
                expectedVersion: .balanceIdEd25519
                ) else {
                    completion(.failed(.failedToDecodeBalanceId(.senderBalanceId)))
                    return
            }
            
            let request = WithdrawalRequest(
                balance: balance,
                amount: xdrAmount,
                universalAmount: 0,
                fee: fee,
                creatorDetails: destAddress,
                ext: .emptyVersion()
            )
            
            let operation = CreateWithdrawalRequestOp(
                request: request,
                allTasks: nil,
                ext: .emptyVersion()
            )
            
            let transactionBuilder: TransactionBuilder = TransactionBuilder(
                networkParams: networkInfo.networkParams,
                sourceAccountId: self.userDataProvider.accountId,
                params: networkInfo.getTxBuilderParams(sendDate: Date())
            )
            
            transactionBuilder.add(
                operationBody: .createWithdrawalRequest(operation),
                operationSourceAccount: self.userDataProvider.accountId
            )
            
            do {
                let transaction = try transactionBuilder.buildTransaction()
                
                try self.transactionSender.sendTransaction(
                    transaction,
                    walletId: self.userDataProvider.walletId,
                    completion: { (result) in
                        switch result {
                            
                        case .succeeded:
                            completion(.succeeded)
                            
                        case .failed(let error):
                            completion(.failed(.sendTransactionError(error)))
                        }
                })
            } catch let error {
                completion(.failed(.sendTransactionError(error)))
            }
        }
    }
}

extension ConfirmationScene.WithdrawConfirmationSectionsProvider: ConfirmationScene.SectionsProvider {
    func observeConfirmationSections() -> Observable<[ConfirmationScene.Model.SectionModel]> {
        return self.sectionsRelay.asObservable()
    }
    
    func loadConfirmationSections() {
        let withdrawAmount = self.amountFormatter.assetAmountToString(self.withdrawModel.amount)
        var cells: [ConfirmationScene.Model.CellModel] = []
        let amountCell = ConfirmationScene.Model.CellModel(
            hint: Localized(.amount),
            cellType: .text(
                value: withdrawAmount + " " + self.withdrawModel.asset
            ),
            identifier: .amount
        )
        cells.append(amountCell)
        
        let senderFee = self.withdrawModel.senderFee.fixed + self.withdrawModel.senderFee.percent
        if senderFee > 0 {
            let senderFeeString = self.amountFormatter.assetAmountToString(senderFee)
            let feeCell = ConfirmationScene.Model.CellModel(
                hint: Localized(.fee),
                cellType: .text(
                    value: senderFeeString + " " + self.withdrawModel.senderFee.asset
                ),
                identifier: .fixedFee
            )
            cells.append(feeCell)
            
            let totalAmount = self.withdrawModel.amount + senderFee
            let totalString = self.amountFormatter.assetAmountToString(totalAmount)
            let totalAmountCell = ConfirmationScene.Model.CellModel(
                hint: Localized(.total),
                cellType: .text(
                    value: totalString + " " + self.withdrawModel.senderFee.asset
                ),
                identifier: .total
            )
            cells.append(totalAmountCell)
        }
        
        let info = Localized(
            .received_amount_may_be_lower_due_to_network_fees,
            replace: [
               .received_amount_may_be_lower_due_to_network_fees_replace_destasset: self.withdrawModel.asset
            ]
        )
        let infoCell = ConfirmationScene.Model.CellModel(
            hint: "",
            cellType: .text(value: info),
            identifier: .toReceive
        )
        cells.append(infoCell)
        
        let destinationCell = ConfirmationScene.Model.CellModel(
            hint: Localized(.destination_address),
            cellType: .text(value: self.withdrawModel.recipientAddress),
            identifier: .destination
        )
        cells.append(destinationCell)
        
        let section = ConfirmationScene.Model.SectionModel(
            title: "",
            cells: cells
        )
        
        self.sectionsRelay.accept([section])
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
        
    }
    
    func handleConfirmAction(completion: @escaping (_ result: ConfirmationResult) -> Void) {
        self.networkInfoFetcher.fetchNetworkInfo { [weak self] (result) in
            switch result {
                
            case .failed(let error):
                completion(.failed(.networkInfoError(error)))
                
            case .succeeded(let networkInfo):
                self?.confirmationWithdrawal(
                    networkInfo: networkInfo,
                    completion: completion
                )
            }
        }
    }
}
