import Foundation
import TokenDSDK
import TokenDWallet
import DLCryptoKit
import RxCocoa
import RxSwift

extension ConfirmationScene {
    class SaleInvestConfirmationProvider {
        
        private let saleInvestModel: Model.SaleInvestModel
        private let transactionSender: TransactionSender
        private let networkInfoFetcher: NetworkInfoFetcher
        private let userDataProvider: UserDataProviderProtocol
        private let amountFormatter: AmountFormatterProtocol
        private let percentFormatter: PercentFormatterProtocol
        private let amountConverter: AmountConverterProtocol
        private let sectionsRelay: BehaviorRelay<[ConfirmationScene.Model.SectionModel]> = BehaviorRelay(value: [])
        
        // MARK: -
        
        init(
            saleInvestModel: Model.SaleInvestModel,
            transactionSender: TransactionSender,
            networkInfoFetcher: NetworkInfoFetcher,
            amountFormatter: AmountFormatterProtocol,
            userDataProvider: UserDataProviderProtocol,
            amountConverter: AmountConverterProtocol,
            percentFormatter: PercentFormatterProtocol
            ) {
            
            self.saleInvestModel = saleInvestModel
            self.transactionSender = transactionSender
            self.networkInfoFetcher = networkInfoFetcher
            self.userDataProvider = userDataProvider
            self.amountFormatter = amountFormatter
            self.amountConverter = amountConverter
            self.percentFormatter = percentFormatter
        }
        
        // MARK: - Private
        
        private func confirmationSaleInvest(
            networkInfo: NetworkInfoModel,
            completion: @escaping (ConfirmationResult) -> Void
            ) {
            
            guard let baseBalance = BalanceID(
                base32EncodedString: self.saleInvestModel.baseBalance,
                expectedVersion: .balanceIdEd25519
                ) else {
                    completion(.failed(.failedToDecodeBalanceId(.baseBalance)))
                    return
            }
            
            guard let quoteBalance = BalanceID(
                base32EncodedString: self.saleInvestModel.quoteBalance,
                expectedVersion: .balanceIdEd25519
                ) else {
                    completion(.failed(.failedToDecodeBalanceId(.quoteBalance)))
                    return
            }
            
            let amount = self.amountConverter.convertDecimalToInt64(
                value: self.saleInvestModel.baseAmount,
                precision: networkInfo.precision
            )
            
            let price = self.amountConverter.convertDecimalToInt64(
                value: self.saleInvestModel.price,
                precision: networkInfo.precision
            )
            
            let fee = self.amountConverter.convertDecimalToInt64(
                value: self.saleInvestModel.fee,
                precision: networkInfo.precision
            )
            
            let manageOfferOp = ManageOfferOp(
                baseBalance: baseBalance,
                quoteBalance: quoteBalance,
                isBuy: self.saleInvestModel.isBuy,
                amount: amount,
                price: price,
                fee: fee,
                offerID: self.saleInvestModel.offerId,
                orderBookID: self.saleInvestModel.orderBookId,
                ext: .emptyVersion()
            )
            
            let transactionBuilder: TransactionBuilder = TransactionBuilder(
                networkParams: networkInfo.networkParams,
                sourceAccountId: self.userDataProvider.accountId,
                params: networkInfo.getTxBuilderParams(sendDate: Date())
            )
            
            if let prevOfferId = self.saleInvestModel.prevOfferId {
                
                let cancelOp = ManageOfferOp(
                    baseBalance: baseBalance,
                    quoteBalance: quoteBalance,
                    isBuy: self.saleInvestModel.isBuy,
                    amount: 0,
                    price: price,
                    fee: fee,
                    offerID: prevOfferId,
                    orderBookID: self.saleInvestModel.orderBookId,
                    ext: .emptyVersion()
                )
                
                transactionBuilder.add(
                    operationBody: .manageOffer(cancelOp),
                    operationSourceAccount: self.userDataProvider.accountId
                )
            }
            
            transactionBuilder.add(
                operationBody: .manageOffer(manageOfferOp),
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
    }
}

extension ConfirmationScene.SaleInvestConfirmationProvider: ConfirmationScene.SectionsProvider {
    func observeConfirmationSections() -> Observable<[ConfirmationScene.Model.SectionModel]> {
        return self.sectionsRelay.asObservable()
    }
    
    func loadConfirmationSections() {
        var sections: [ConfirmationScene.Model.SectionModel] = []
        let tokenCell = ConfirmationScene.Model.CellModel(
            hint: Localized(.sale),
            cellType: .text(value: self.saleInvestModel.baseAssetName),
            identifier: .sale
        )
        
        let tokenSection = ConfirmationScene.Model.SectionModel(
            title: "",
            cells: [tokenCell]
        )
        
        sections.append(tokenSection)
        
        var toPayCells: [ConfirmationScene.Model.CellModel] = []
        let amountCellText = self.amountFormatter.assetAmountToString(
            self.saleInvestModel.quoteAmount
            ) + " " + self.saleInvestModel.quoteAsset
        
        let amountCell = ConfirmationScene.Model.CellModel(
            hint: Localized(.amount),
            cellType: .text(value: amountCellText),
            identifier: .amount
        )
        toPayCells.append(amountCell)
        
        if self.saleInvestModel.fee > 0 {
            let feeCellText = self.amountFormatter.assetAmountToString(
                self.saleInvestModel.fee
                ) + " " + self.saleInvestModel.quoteAsset
            
            let feeCell = ConfirmationScene.Model.CellModel(
                hint: Localized(.fee),
                cellType: .text(value: feeCellText),
                identifier: .fee
            )
            toPayCells.append(feeCell)
            
            let toPayCellAmount = self.saleInvestModel.fee + self.saleInvestModel.quoteAmount
            let toPayCellAmountFormatted = self.amountFormatter.assetAmountToString(toPayCellAmount)
            let toPayCellText = toPayCellAmountFormatted + " " + self.saleInvestModel.quoteAsset
            
            let toPayCell = ConfirmationScene.Model.CellModel(
                hint: Localized(.total),
                cellType: .text(value: toPayCellText),
                identifier: .total
            )
            toPayCells.append(toPayCell)
        }
        
        let toPaySection = ConfirmationScene.Model.SectionModel(
            title: Localized(.to_pay),
            cells: toPayCells
        )
        sections.append(toPaySection)
        
        let saleInvestBaseAmount = self.amountFormatter.assetAmountToString(self.saleInvestModel.baseAmount)
        let toReceiveText = "\(saleInvestBaseAmount) \(self.saleInvestModel.baseAsset)"
        
        let toReceiveCell = ConfirmationScene.Model.CellModel(
            hint: Localized(.amount),
            cellType: .text(value: toReceiveText),
            identifier: .amount
        )
        
        let receiveSection = ConfirmationScene.Model.SectionModel(
            title: Localized(.to_receive),
            cells: [toReceiveCell]
        )
        sections.append(receiveSection)
        
        self.sectionsRelay.accept(sections)
    }
    
    func handleTextEdit(
        identifier: ConfirmationScene.CellIdentifier,
        value: String?
        ) { }
    
    func handleBoolSwitch(
        identifier: ConfirmationScene.CellIdentifier,
        value: Bool
        ) { }
    
    func handleConfirmAction(completion: @escaping (_ result: ConfirmationResult) -> Void) {
        self.networkInfoFetcher.fetchNetworkInfo { [weak self] (result) in
            switch result {
                
            case .failed(let error):
                completion(.failed(.networkInfoError(error)))
                
            case .succeeded(let networkInfo):
                self?.confirmationSaleInvest(
                    networkInfo: networkInfo,
                    completion: completion
                )
            }
        }
    }
}
