import Foundation
import RxSwift
import RxCocoa
import TokenDSDK
import TokenDWallet

extension TransactionDetails {
    class PendingOfferSectionsProvider {
        
        private let pendingOffersRepo: PendingOffersRepo
        private let transactionSender: TransactionSender
        private let amountConverter: AmountConverterProtocol
        private let networkInfoFetcher: NetworkInfoFetcher
        private let userDataProvider: UserDataProviderProtocol
        private let identifier: UInt64
        
        init(
            pendingOffersRepo: PendingOffersRepo,
            transactionSender: TransactionSender,
            amountConverter: AmountConverterProtocol,
            networkInfoFetcher: NetworkInfoFetcher,
            userDataProvider: UserDataProviderProtocol,
            identifier: UInt64
            ) {
            
            self.pendingOffersRepo = pendingOffersRepo
            self.transactionSender = transactionSender
            self.amountConverter = amountConverter
            self.networkInfoFetcher = networkInfoFetcher
            self.userDataProvider = userDataProvider
            self.identifier = identifier
        }
        
        private func getSectionsForOffer(
            _ offer: PendingOffersRepo.Offer
            ) -> [TransactionDetails.Model.SectionModel] {
            
            let dateFormatter = TransactionDetails.DateFormatter()
            let amountFormatter = TransactionDetails.AmountFormatter()
            
            var sections: [Model.SectionModel] = []
            
            let replacePrice = amountFormatter.assetAmountToString(offer.price)
            let price = Localized(
                .one_equals,
                replace: [
                    .one_equals_replace_base_asset: offer.baseAssetCode,
                    .one_equals_replace_quote_asset: offer.quoteAssetCode,
                    .one_equals_replace_price: replacePrice
                ]
            )
            let priceCell = Model.CellModel(
                title: price,
                hint: Localized(.price),
                identifier: .price
            )
            let dateCell = TransactionDetails.Model.CellModel(
                title: dateFormatter.dateToString(date: offer.createdAt),
                hint: Localized(.date),
                identifier: .date
            )
            let infoSection = Model.SectionModel(
                title: "",
                cells: [priceCell, dateCell],
                description: ""
            )
            sections.append(infoSection)
            
            let quoteAmountTitle = amountFormatter.formatAmount(
                offer.quoteAmount,
                currency: offer.quoteAssetCode
            )
            let toPayCell = Model.CellModel(
                title: quoteAmountTitle,
                hint: Localized(.amount),
                identifier: .amount
            )
            let toPaySection = Model.SectionModel(
                title: Localized(.to_pay),
                cells: [toPayCell],
                description: ""
            )
            sections.append(toPaySection)
            
            let baseAmountTitle = amountFormatter.formatAmount(
                offer.baseAmount,
                currency: offer.baseAssetCode
            )
            let toReceiveCell = Model.CellModel(
                title: baseAmountTitle,
                hint: Localized(.amount),
                identifier: .amount
            )
            let toReceiveSection = Model.SectionModel(
                title: Localized(.to_receive),
                cells: [toReceiveCell],
                description: ""
            )
            sections.append(toReceiveSection)
            
            return sections
        }
    }
}

extension TransactionDetails.PendingOfferSectionsProvider: TransactionDetails.SectionsProviderProtocol {
    func observeTransaction() -> Observable<[TransactionDetails.Model.SectionModel]> {
        
        return self.pendingOffersRepo
            .observeOffers()
            .map { [weak self] (offers) -> [TransactionDetails.Model.SectionModel] in
                guard let offer = offers.first(where: { [weak self] (offer) -> Bool in
                    return offer.offerId == self?.identifier
                }) else {
                    return []
                }
                return self?.getSectionsForOffer(offer) ?? []
        }
    }
    
    private var offer: PendingOffersRepo.Offer? {
        return self.pendingOffersRepo.offersValue.first(where: { (response) -> Bool in
            return response.offerId == self.identifier
        })
    }
    
    private enum PendingOfferAction: String {
        case cancel
        
        var icon: UIImage {
            switch self {
            case .cancel:
                return Assets.delete.image
            }
        }
    }
    
    func getActions() -> [TransactionDetailsProviderProtocol.Action] {
        let actions: [PendingOfferAction] = [.cancel]
        
        return actions.map({ (action) -> TransactionDetailsProviderProtocol.Action in
            return TransactionDetailsProviderProtocol.Action(
                id: action.rawValue,
                icon: action.icon
            )
        })
    }
    
    func performActionWithId(
        _ id: String,
        onSuccess: @escaping () -> Void,
        onShowLoading: @escaping () -> Void,
        onHideLoading: @escaping () -> Void,
        onError: @escaping (String) -> Void
        ) {
        guard let action = PendingOfferAction(rawValue: id),
            let offer = self.offer else {
                return
        }
        
        switch action {
        case .cancel:
            self.cancelOffer(
                offer: offer,
                onSuccess: onSuccess,
                onShowLoading: onShowLoading,
                onHideLoading: onHideLoading,
                onError: onError
            )
        }
    }
    
    private func cancelOffer(
        offer: PendingOffersRepo.Offer,
        onSuccess: @escaping () -> Void,
        onShowLoading: @escaping () -> Void,
        onHideLoading: @escaping () -> Void,
        onError: @escaping (String) -> Void
        ) {
        
        onShowLoading()
        self.networkInfoFetcher.fetchNetworkInfo { [weak self] (result) in
            switch result {
            case .succeeded(let networkInfo):
                self?.cancelOffer(
                    offer: offer,
                    networkInfo: networkInfo,
                    onSuccess: onSuccess,
                    onShowLoading: onShowLoading,
                    onHideLoading: onHideLoading,
                    onError: onError
                )
            case .failed(let error):
                onError(error.localizedDescription)
                onHideLoading()
            }
        }
    }
    
    private func cancelOffer(
        offer: PendingOffersRepo.Offer,
        networkInfo: NetworkInfoModel,
        onSuccess: @escaping () -> Void,
        onShowLoading: @escaping () -> Void,
        onHideLoading: @escaping () -> Void,
        onError: @escaping (String) -> Void
        ) {
        
        guard let baseBalanceId = BalanceID(
            base32EncodedString: offer.baseBalanceId,
            expectedVersion: .balanceIdEd25519
            ) else {
                onError(Localized(.failed_to_decode_base_balance_id))
                onHideLoading()
                return
        }
        
        guard let quoteBalanceId = BalanceID(
            base32EncodedString: offer.quoteBalanceId,
            expectedVersion: .balanceIdEd25519
            ) else {
                onError(Localized(.failed_to_decode_quote_balance_id))
                onHideLoading()
                return
        }
        
        let operation = ManageOfferOp(
            baseBalance: baseBalanceId,
            quoteBalance: quoteBalanceId,
            isBuy: offer.isBuy,
            amount: 0,
            price: self.amountConverter.convertDecimalToInt64(value: offer.price, precision: networkInfo.precision),
            fee: self.amountConverter.convertDecimalToInt64(value: offer.fee, precision: networkInfo.precision),
            offerID: offer.offerId,
            orderBookID: 0,
            ext: .emptyVersion()
        )
        
        let transactionBuilder = TransactionBuilder(
            networkParams: networkInfo.networkParams,
            sourceAccountId: self.userDataProvider.accountId,
            params: networkInfo.getTxBuilderParams(sendDate: Date())
        )
        
        transactionBuilder.add(
            operationBody: .manageOffer(operation),
            operationSourceAccount: self.userDataProvider.accountId
        )
        do {
            let transaction = try transactionBuilder.buildTransaction()
            
            try self.transactionSender.sendTransaction(
                transaction,
                walletId: self.userDataProvider.walletId,
                completion: { [weak self] (result) in
                    switch result {
                    case .succeeded:
                        self?.pendingOffersRepo.reloadOffers(completion: {
                            onSuccess()
                        })
                    case .failed(let error):
                        onError(error.localizedDescription)
                    }
                    onHideLoading()
            })
        } catch let error {
            onError(error.localizedDescription)
            onHideLoading()
        }
    }
}
