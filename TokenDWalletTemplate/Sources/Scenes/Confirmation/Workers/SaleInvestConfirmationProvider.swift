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
            title: Localized(.token),
            cellType: .text(value: self.saleInvestModel.baseAsset),
            identifier: .token
        )
        
        let tokenSection = ConfirmationScene.Model.SectionModel(
            cells: [tokenCell]
        )
        
        sections.append(tokenSection)
        
        let amountCellText = self.amountFormatter.assetAmountToString(
            self.saleInvestModel.quoteAmount
            ) + " " + self.saleInvestModel.quoteAsset
        
        let amountCell = ConfirmationScene.Model.CellModel(
            title: Localized(.investment),
            cellType: .text(value: amountCellText),
            identifier: .investment
        )
        
        let feeCellText = self.amountFormatter.assetAmountToString(
            self.saleInvestModel.fee
            ) + " " + self.saleInvestModel.quoteAsset
        
        let feeCell = ConfirmationScene.Model.CellModel(
            title: Localized(.fee),
            cellType: .text(value: feeCellText),
            identifier: .fee
        )
        
        let toPayCellAmount = self.saleInvestModel.fee + self.saleInvestModel.quoteAmount
        let toPayCellAmountFormatted = self.amountFormatter.assetAmountToString(toPayCellAmount)
        let toPayCellText = toPayCellAmountFormatted + " " + self.saleInvestModel.quoteAsset
        
        let toPayCell = ConfirmationScene.Model.CellModel(
            title: Localized(.to_pay),
            cellType: .text(value: toPayCellText),
            identifier: .toPay
        )
        
        let amountSection = ConfirmationScene.Model.SectionModel(cells: [amountCell, feeCell, toPayCell])
        
        sections.append(amountSection)
        
        if self.saleInvestModel.type == SaleResponse.SaleType.SaleTypeValue.basic.rawValue {
            let baseAsset = self.saleInvestModel.baseAsset
            let quoteAsset = self.saleInvestModel.quoteAsset
            let saleInvestPriceAmount = self.amountFormatter.assetAmountToString(self.saleInvestModel.price)
            let pricecelltext = Localized(
                .one_for,
                replace: [
                    .one_for_replace_base_asset: baseAsset,
                    .one_for_replace_quote_asset: quoteAsset,
                    .one_for_replace_sale_invest_price_amount: saleInvestPriceAmount
                    
                ]
            )
            
            let priceCell = ConfirmationScene.Model.CellModel(
                title: Localized(.price),
                cellType: .text(value: pricecelltext),
                identifier: .price
            )
            
            let saleInvestBaseAmount = self.amountFormatter.assetAmountToString(self.saleInvestModel.baseAmount)
            let toReceiveText = "\(saleInvestBaseAmount) \(baseAsset)"
            
            let toReceiveCell = ConfirmationScene.Model.CellModel(
                title: Localized(.to_receive),
                cellType: .text(value: toReceiveText),
                identifier: .toReceive
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
