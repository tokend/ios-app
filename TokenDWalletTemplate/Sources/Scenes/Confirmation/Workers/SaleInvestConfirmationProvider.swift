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
        private let amountPrecision: Int
        private let sectionsRelay: BehaviorRelay<[ConfirmationScene.Model.SectionModel]> = BehaviorRelay(value: [])
        
        // MARK: -
        
        init(
            saleInvestModel: Model.SaleInvestModel,
            transactionSender: TransactionSender,
            networkInfoFetcher: NetworkInfoFetcher,
            amountFormatter: AmountFormatterProtocol,
            userDataProvider: UserDataProviderProtocol,
            amountConverter: AmountConverterProtocol,
            percentFormatter: PercentFormatterProtocol,
            amountPrecision: Int
            ) {
            self.saleInvestModel = saleInvestModel
            self.transactionSender = transactionSender
            self.networkInfoFetcher = networkInfoFetcher
            self.userDataProvider = userDataProvider
            self.amountFormatter = amountFormatter
            self.amountConverter = amountConverter
            self.amountPrecision = amountPrecision
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
                    completion(.failed(.failedToDecodeBalanceId("baseBalance")))
                    return
            }
            
            guard let quoteBalance = BalanceID(
                base32EncodedString: self.saleInvestModel.quoteBalance,
                expectedVersion: .balanceIdEd25519
                ) else {
                    completion(.failed(.failedToDecodeBalanceId("quoteBalance")))
                    return
            }
            
            let amount = self.amountConverter.convertDecimalToInt64(
                value: self.saleInvestModel.baseAmount,
                precision: self.amountPrecision
            )
            
            let price = self.amountConverter.convertDecimalToInt64(
                value: self.saleInvestModel.price,
                precision: self.amountPrecision
            )
            
            let fee = self.amountConverter.convertDecimalToInt64(
                value: self.saleInvestModel.fee,
                precision: self.amountPrecision
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
            title: "Token",
            cellType: .text(value: self.saleInvestModel.baseAsset),
            identifier: "tokenCell")
        
        let tokenSection = ConfirmationScene.Model.SectionModel(
            cells: [tokenCell]
        )
        
        sections.append(tokenSection)
        
        let amountCellText = self.amountFormatter.assetAmountToString(
            self.saleInvestModel.quoteAmount
            ) + " " + self.saleInvestModel.quoteAsset
        
        let amountCell = ConfirmationScene.Model.CellModel(
            title: "Investment",
            cellType: .text(value: amountCellText),
            identifier: "investmentCell"
        )
        
        let feeCellText = self.amountFormatter.assetAmountToString(
            self.saleInvestModel.fee
            ) + " " + self.saleInvestModel.quoteAsset
        
        let feeCell = ConfirmationScene.Model.CellModel(
            title: "Fee",
            cellType: .text(value: feeCellText),
            identifier: "feeCell"
        )
        
        let toPayCellAmount = self.saleInvestModel.fee + self.saleInvestModel.quoteAmount
        let toPayCellAmountFormatted = self.amountFormatter.assetAmountToString(toPayCellAmount)
        let toPayCellText = toPayCellAmountFormatted + " " + self.saleInvestModel.quoteAsset
        
        let toPayCell = ConfirmationScene.Model.CellModel(
            title: "To pay",
            cellType: .text(value: toPayCellText),
            identifier: "toPayCell"
        )
        
        let amountSection = ConfirmationScene.Model.SectionModel(cells: [amountCell, feeCell, toPayCell])
        
        sections.append(amountSection)
        
        if self.saleInvestModel.type == SaleResponse.SaleType.SaleTypeValue.basic.rawValue {
            let baseAsset = self.saleInvestModel.baseAsset
            let quoteAsset = self.saleInvestModel.quoteAsset
            let saleInvestPriceAmount = self.amountFormatter.assetAmountToString(self.saleInvestModel.price)
            let priceCellText = "1 \(baseAsset) for \(saleInvestPriceAmount) \(quoteAsset)"
            
            let priceCell = ConfirmationScene.Model.CellModel(
                title: "Price",
                cellType: .text(value: priceCellText),
                identifier: "priceCell"
            )
            
            let saleInvestBaseAmount = self.amountFormatter.assetAmountToString(self.saleInvestModel.baseAmount)
            let toReceiveText = "\(saleInvestBaseAmount) \(baseAsset)"
            
            let toReceiveCell = ConfirmationScene.Model.CellModel(
                title: "To receive",
                cellType: .text(value: toReceiveText),
                identifier: "toReceiveCell"
            )
            
            let receiveSection = ConfirmationScene.Model.SectionModel(
                cells: [priceCell, toReceiveCell]
            )
            
            sections.append(receiveSection)
        }
        
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
