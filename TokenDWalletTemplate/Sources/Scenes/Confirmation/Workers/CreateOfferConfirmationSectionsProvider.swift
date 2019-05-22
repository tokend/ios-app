import Foundation
import TokenDWallet
import TokenDSDK
import RxSwift
import RxCocoa

extension ConfirmationScene {
    
    class CreateOfferConfirmationSectionsProvider {
        
        // MARK: - Private properties
        
        private let createOfferModel: Model.CreateOfferModel
        private let transactionSender: TransactionSender
        private let networkInfoFetcher: NetworkInfoFetcher
        private let userDataProvider: UserDataProviderProtocol
        private let amountFormatter: AmountFormatterProtocol
        private let amountConverter: AmountConverterProtocol
        private let balanceCreator: BalanceCreatorProtocol
        private let balancesRepo: BalancesRepo
        private let pendingOffersRepo: PendingOffersRepo
        
        private let sectionsRelay: BehaviorRelay<[Model.SectionModel]> = BehaviorRelay(value: [])
        
        // MARK: -
        
        init(
            createOfferModel: Model.CreateOfferModel,
            transactionSender: TransactionSender,
            networkInfoFetcher: NetworkInfoFetcher,
            userDataProvider: UserDataProviderProtocol,
            amountFormatter: AmountFormatterProtocol,
            amountConverter: AmountConverterProtocol,
            balanceCreator: BalanceCreatorProtocol,
            balancesRepo: BalancesRepo,
            pendingOffersRepo: PendingOffersRepo
            ) {
            
            self.createOfferModel = createOfferModel
            self.transactionSender = transactionSender
            self.networkInfoFetcher = networkInfoFetcher
            self.userDataProvider = userDataProvider
            self.amountFormatter = amountFormatter
            self.amountConverter = amountConverter
            self.balanceCreator = balanceCreator
            self.balancesRepo = balancesRepo
            self.pendingOffersRepo = pendingOffersRepo
        }
        
        // MARK: - Private
        
        private func confirmationCreateOffer(
            networkInfo: NetworkInfoModel,
            completion: @escaping (ConfirmationResult) -> Void
            ) {
            
            var baseBalance: TokenDSDK.BalanceDetails?
            var quoteBalance: TokenDSDK.BalanceDetails?
            
            let group = DispatchGroup()
            
            group.enter()
            self.balanceForAsset(self.createOfferModel.baseAsset, completion: { (result) in
                switch result {
                case .balance(let balance):
                    baseBalance = balance
                case .error:
                    break
                }
                group.leave()
            })
            
            group.enter()
            self.balanceForAsset( self.createOfferModel.quoteAsset, completion: { (result) in
                switch result {
                case .balance(let balance):
                    quoteBalance = balance
                case .error:
                    break
                }
                group.leave()
            })
            
            group.notify(
                queue: DispatchQueue.global(),
                execute: { [weak self] in
                    guard let strongSelf = self else { return }
                    
                    guard let baseBalance = baseBalance else {
                        completion(.failed(.failedToCreateBalance(asset: strongSelf.createOfferModel.baseAsset)))
                        return
                    }
                    guard let quoteBalance = quoteBalance else {
                        completion(.failed(.failedToCreateBalance(asset: strongSelf.createOfferModel.quoteAsset)))
                        return
                    }
                    
                    let offer = strongSelf.createOfferModel
                    let quoteAmount = offer.price * offer.amount
                    
                    if quoteAmount <= 0 {
                        completion(.failed(.notEnoughData))
                        return
                    }
                    if offer.isBuy {
                        if quoteAmount + offer.fee > quoteBalance.balance {
                            completion(.failed(.notEnoughMoneyOnBalance(asset: quoteBalance.asset)))
                            return
                        }
                    } else {
                        if quoteAmount - offer.fee <= 0 {
                            completion(.failed(.other(NSError(
                                domain: Localized(.order_price_cannot_be_less_than_or_equal_to_0),
                                code: 1111,
                                userInfo: nil)
                                ))
                            )
                            return
                        }
                        if offer.amount > baseBalance.balance {
                            completion(.failed(.notEnoughMoneyOnBalance(asset: baseBalance.asset)))
                            return
                        }
                    }
                    
                    guard let baseBalanceId = BalanceID(
                        base32EncodedString: baseBalance.balanceId,
                        expectedVersion: .balanceIdEd25519
                        ) else {
                            completion(.failed(.failedToDecodeBalanceId(.baseBalanceId)))
                            return
                    }
                    
                    guard let quoteBalanceId = BalanceID(
                        base32EncodedString: quoteBalance.balanceId,
                        expectedVersion: .balanceIdEd25519
                        ) else {
                            completion(.failed(.failedToDecodeBalanceId(.quoteBalanceId)))
                            return
                    }
                    
                    let amount = strongSelf.amountConverter.convertDecimalToInt64(
                        value: strongSelf.createOfferModel.amount,
                        precision: networkInfo.precision
                    )
                    let price = strongSelf.amountConverter.convertDecimalToInt64(
                        value: strongSelf.createOfferModel.price,
                        precision: networkInfo.precision
                    )
                    let fee = strongSelf.amountConverter.convertDecimalToInt64(
                        value: strongSelf.createOfferModel.fee,
                        precision: networkInfo.precision
                    )
                    
                    let operation = ManageOfferOp(
                        baseBalance: baseBalanceId,
                        quoteBalance: quoteBalanceId,
                        isBuy: strongSelf.createOfferModel.isBuy,
                        amount: amount,
                        price: price,
                        fee: fee,
                        offerID: 0,
                        orderBookID: 0,
                        ext: .emptyVersion()
                    )
                    
                    let transactionBuilder = TransactionBuilder(
                        networkParams: networkInfo.networkParams,
                        sourceAccountId: strongSelf.userDataProvider.accountId,
                        params: networkInfo.getTxBuilderParams(sendDate: Date())
                    )
                    
                    transactionBuilder.add(
                        operationBody: .manageOffer(operation),
                        operationSourceAccount: strongSelf.userDataProvider.accountId
                    )
                    do {
                        let transaction = try transactionBuilder.buildTransaction()
                        
                        try strongSelf.transactionSender.sendTransaction(
                            transaction,
                            walletId: strongSelf.userDataProvider.walletId,
                            completion: { (result) in
                                self?.pendingOffersRepo.reloadOffers()
                                
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
            })
        }
        
        enum BalanceForAssetResult {
            case balance(TokenDSDK.BalanceDetails)
            case error
        }
        private func balanceForAsset(
            _ asset: String,
            completion: @escaping (BalanceForAssetResult) -> Void
            ) {
            
            let balanceForAssetClosure: (String) -> TokenDSDK.BalanceDetails? = { (asset) in
                if let balanceState = self.balancesRepo.balancesDetailsValue.first(where: { (state) -> Bool in
                    return state.asset == asset
                }),
                    case .created(let balance) = balanceState {
                    return balance
                }
                return nil
            }
            
            if let balance = balanceForAssetClosure(asset) {
                completion(.balance(balance))
                return
            }
            
            self.balanceCreator.createBalanceForAsset(
                asset,
                completion: { (result) in
                    switch result {
                    case .succeeded:
                        if let balance = balanceForAssetClosure(asset) {
                            completion(.balance(balance))
                        } else {
                            completion(.error)
                        }
                    case .failed:
                        completion(.error)
                    }
            })
        }
        
        private func createToPaySection(
            offer: Model.CreateOfferModel,
            isBuy: Bool,
            quoteAmount: Decimal
            ) -> ConfirmationScene.Model.SectionModel {
            
            var toPayCells: [ConfirmationScene.Model.CellModel] = []
            
            let toPayAmount = isBuy ? quoteAmount : offer.amount
            let toPayFee = isBuy ? offer.fee : nil
            let toPayAsset = isBuy ? offer.quoteAsset : offer.baseAsset
            
            let toPayAmountString = self.amountFormatter.assetAmountToString(toPayAmount) + " " + toPayAsset
            let toPayAmountCell = ConfirmationScene.Model.CellModel(
                hint: Localized(.amount),
                cellType: .text(value: toPayAmountString),
                identifier: .amount
            )
            toPayCells.append(toPayAmountCell)
            
            if let fee = toPayFee,
                fee > 0 {
                let feeString = self.amountFormatter.assetAmountToString(fee) + " " + toPayAsset
                let feeCell = ConfirmationScene.Model.CellModel(
                    hint: Localized(.fee),
                    cellType: .text(value: feeString),
                    identifier: .toPayFee
                )
                toPayCells.append(feeCell)
                
                let toPayTotalString = self.amountFormatter.assetAmountToString(toPayAmount + fee) + " " + toPayAsset
                
                let toPayTotalCell = ConfirmationScene.Model.CellModel(
                    hint: Localized(.total),
                    cellType: .text(value: toPayTotalString),
                    identifier: .total
                )
                toPayCells.append(toPayTotalCell)
            }
            
            return Model.SectionModel(
                title: Localized(.to_pay),
                cells: toPayCells
            )
        }
        
        private func createToReceiveSection(
            offer: Model.CreateOfferModel,
            isBuy: Bool,
            quoteAmount: Decimal
            ) -> ConfirmationScene.Model.SectionModel {
            
            let toReceiveAmount = isBuy ? offer.amount : quoteAmount
            let toReceiveFee = isBuy ? nil : offer.fee
            let toReceiveAsset = isBuy ? offer.baseAsset : offer.quoteAsset
            
            var toReceiveCells: [ConfirmationScene.Model.CellModel] = []
            
            let toReceiveAmountString = self.amountFormatter.assetAmountToString(toReceiveAmount) + " " + toReceiveAsset
            let toReceiveAmountCell = ConfirmationScene.Model.CellModel(
                hint: Localized(.amount),
                cellType: .text(value: toReceiveAmountString),
                identifier: .amount
            )
            toReceiveCells.append(toReceiveAmountCell)
            
            if let fee = toReceiveFee,
                fee > 0 {
                let feeString = self.amountFormatter.assetAmountToString(fee) + " " + offer.quoteAsset
                let feeCell = ConfirmationScene.Model.CellModel(
                    hint: Localized(.fee),
                    cellType: .text(value: feeString),
                    identifier: .toReceiveFee
                )
                toReceiveCells.append(feeCell)
                
                let toReceiveTotalAmount = self.amountFormatter.assetAmountToString(toReceiveAmount - fee)
                let toReceiveTotalString = toReceiveTotalAmount + " " + offer.quoteAsset
                
                let toReceiveTotalCell = ConfirmationScene.Model.CellModel(
                    hint: Localized(.total),
                    cellType: .text(value: toReceiveTotalString),
                    identifier: .total
                )
                toReceiveCells.append(toReceiveTotalCell)
            }
            
            return Model.SectionModel(
                title: Localized(.to_receive),
                cells: toReceiveCells
            )
        }
    }
}

// MARK: - ConfirmationScene.SectionsProvider

extension ConfirmationScene.CreateOfferConfirmationSectionsProvider: ConfirmationScene.SectionsProvider {
    func observeConfirmationSections() -> Observable<[ConfirmationScene.Model.SectionModel]> {
        return self.sectionsRelay.asObservable()
    }
    
    func loadConfirmationSections() {
        var sections: [ConfirmationScene.Model.SectionModel] = []
        
        let priceString = self.amountFormatter.assetAmountToString(self.createOfferModel.price)
        let price = Localized(
            .one_equals,
            replace: [
                .one_equals_replace_base_asset: self.createOfferModel.baseAsset,
                .one_equals_replace_quote_asset: self.createOfferModel.quoteAsset,
                .one_equals_replace_price: priceString
                ]
        )
        let priceCell = ConfirmationScene.Model.CellModel(
            hint: Localized(.price),
            cellType: .text(value: price),
            identifier: .price
        )
        let priceSection = ConfirmationScene.Model.SectionModel(
            title: "",
            cells: [priceCell]
        )
        sections.append(priceSection)
        
        let offer = self.createOfferModel
        let quoteAmount = offer.price * offer.amount
        let isBuy = offer.isBuy
        
        let toPaySection = self.createToPaySection(
            offer: offer,
            isBuy: isBuy,
            quoteAmount: quoteAmount
        )
        sections.append(toPaySection)
        
        let toReceiveSection = self.createToReceiveSection(
            offer: offer,
            isBuy: isBuy,
            quoteAmount: quoteAmount
        )
        sections.append(toReceiveSection)
        
        self.sectionsRelay.accept(sections)
    }
    
    func handleTextEdit(identifier: ConfirmationScene.CellIdentifier, value: String?) { }
    
    func handleBoolSwitch(identifier: ConfirmationScene.CellIdentifier, value: Bool) { }
    
    func handleConfirmAction(completion: @escaping (ConfirmationResult) -> Void) {
        self.networkInfoFetcher.fetchNetworkInfo { [weak self] (result) in
            switch result {
                
            case .failed(let error):
                completion(.failed(.networkInfoError(error)))
                
            case .succeeded(let networkInfo):
                self?.confirmationCreateOffer(
                    networkInfo: networkInfo,
                    completion: completion
                )
            }
        }
    }
}
