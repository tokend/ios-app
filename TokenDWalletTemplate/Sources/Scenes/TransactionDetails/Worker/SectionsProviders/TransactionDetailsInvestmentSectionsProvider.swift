import Foundation
import RxSwift
import RxCocoa
import TokenDSDK
import TokenDWallet

extension TransactionDetails {
    class InvestmentSectionsProvider {
        
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
            
            let tokenCell = Model.CellModel(
                title: offer.baseAssetCode,
                hint: Localized(.asset),
                identifier: .token
            )
            let dateCell = TransactionDetails.Model.CellModel(
                title: dateFormatter.dateToString(date: offer.createdAt),
                hint: Localized(.date),
                identifier: .date,
                isSeparatorHidden: true
            )
            let infoSection = Model.SectionModel(
                title: "",
                cells: [tokenCell, dateCell],
                description: ""
            )
            sections.append(infoSection)
            
            var toPayCells: [Model.CellModel] = []
            let quoteAmountTitle = amountFormatter.formatAmount(
                offer.quoteAmount,
                currency: offer.quoteAssetCode
            )
            let toPayCell = Model.CellModel(
                title: quoteAmountTitle,
                hint: Localized(.amount),
                identifier: .amount,
                isSeparatorHidden: true
            )
            toPayCells.append(toPayCell)
            if offer.fee > 0 {
                if let index = toPayCells.indexOf(toPayCell) {
                    toPayCells[index].isSeparatorHidden = false
                }
                let formattedAmount = amountFormatter.assetAmountToString(offer.fee)
                let feeCellText = formattedAmount + " " + offer.quoteAssetCode
                
                let feeCell = Model.CellModel(
                    title: feeCellText,
                    hint: Localized(.fee),
                    identifier: .fee
                )
                toPayCells.append(feeCell)
                
                let formattedTotalFeeAmount = amountFormatter.assetAmountToString(offer.fee + offer.quoteAmount)
                let totalFeeCell = Model.CellModel(
                    title: formattedTotalFeeAmount,
                    hint: Localized(.total),
                    identifier: .total,
                    isSeparatorHidden: true
                )
                toPayCells.append(totalFeeCell)
            }
            let toPaySection = Model.SectionModel(
                title: Localized(.to_pay),
                cells: toPayCells,
                description: ""
            )
            sections.append(toPaySection)
            return sections
        }
    }
}

extension TransactionDetails.InvestmentSectionsProvider: TransactionDetails.SectionsProviderProtocol {
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
        
        var title: String {
            switch self {
            case .cancel:
                return Localized(.cancel_investment)
            }
        }
        
        var message: String {
            switch self {
            case .cancel:
                return Localized(.are_you_sure_you_want_to_cancel_investment)
            }
        }
    }
    
    func getActions() -> [TransactionDetailsProviderProtocol.Action] {
        let actions: [PendingOfferAction] = [.cancel]
        
        return actions.map({ (action) -> TransactionDetailsProviderProtocol.Action in
            return TransactionDetailsProviderProtocol.Action(
                id: action.rawValue,
                icon: action.icon,
                title: action.title,
                message: action.message
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
            orderBookID: Uint64(offer.orderBookId),
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
