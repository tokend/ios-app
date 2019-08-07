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
        private let amountPrecision: Int
        private let sectionsRelay: BehaviorRelay<[ConfirmationScene.Model.SectionModel]> = BehaviorRelay(value: [])
        
        // MARK: -
        
        init(
            withdrawModel: Model.WithdrawModel,
            transactionSender: TransactionSender,
            networkInfoFetcher: NetworkInfoFetcher,
            amountFormatter: AmountFormatterProtocol,
            userDataProvider: UserDataProviderProtocol,
            amountConverter: AmountConverterProtocol,
            percentFormatter: PercentFormatterProtocol,
            amountPrecision: Int
            ) {
            
            self.withdrawModel = withdrawModel
            self.transactionSender = transactionSender
            self.networkInfoFetcher = networkInfoFetcher
            self.userDataProvider = userDataProvider
            self.amountFormatter = amountFormatter
            self.amountConverter = amountConverter
            self.amountPrecision = amountPrecision
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
                precision: self.amountPrecision
            )
            
            let conversion = AutoConversionWithdrawalDetails(
                destAsset: self.withdrawModel.asset,
                expectedAmount: xdrAmount,
                ext: .emptyVersion()
            )
            
            let fee = Fee(
                fixed: 0,
                percent: 0,
                ext: .emptyVersion()
            )
            
            let details = WithdrawalRequest.WithdrawalRequestDetails.autoConversion(conversion)
            
            guard let balance = BalanceID(
                base32EncodedString: self.withdrawModel.senderBalanceId,
                expectedVersion: .balanceIdEd25519
                ) else {
                    completion(.failed(.failedToDecodeBalanceId(self.withdrawModel.senderBalanceId)))
                    return
            }
            
            let request = WithdrawalRequest(
                balance: balance,
                amount: xdrAmount,
                universalAmount: 0,
                fee: fee,
                externalDetails: destAddress,
                preConfirmationDetails: "",
                details: details,
                ext: .emptyVersion()
            )
            
            let operation = CreateWithdrawalRequestOp(
                request: request,
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
        let destinationCell = ConfirmationScene.Model.CellModel(
            title: "Destination address",
            cellType: .text(value: self.withdrawModel.recipientAddress),
            identifier: "destinationCell"
        )
        let destinationSection = ConfirmationScene.Model.SectionModel(cells: [destinationCell])
        
        let withdrawAmount = self.amountFormatter.assetAmountToString(self.withdrawModel.amount)
        let amountCell = ConfirmationScene.Model.CellModel(
            title: "Amount",
            cellType: .text(
                value: withdrawAmount + " " + self.withdrawModel.asset
            ),
            identifier: "amountCell"
        )
        
        let senderFeeFixed = self.amountFormatter.assetAmountToString(self.withdrawModel.senderFee.fixed)
        let fixedFeeCell = ConfirmationScene.Model.CellModel(
            title: "Fixed Fee",
            cellType: .text(
                value: senderFeeFixed + " " + self.withdrawModel.asset
            ),
            identifier: "fixedFeeCell"
        )
        
        let senderFeePercent = self.percentFormatter.percentToString(value: self.withdrawModel.senderFee.percent)
        let percentFeeCell = ConfirmationScene.Model.CellModel(
            title: "Percent Fee",
            cellType: .text(
                value: senderFeePercent + " " + self.withdrawModel.asset
            ),
            identifier: "percentFeeCell"
        )
        let toPaySection = ConfirmationScene.Model.SectionModel(cells: [amountCell, fixedFeeCell, percentFeeCell])
        
        self.sectionsRelay.accept([
            destinationSection,
            toPaySection
            ]
        )
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
