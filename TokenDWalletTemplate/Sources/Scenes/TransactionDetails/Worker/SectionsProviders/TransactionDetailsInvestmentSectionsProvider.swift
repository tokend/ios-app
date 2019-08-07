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
        private let amountPrecision: Int
        private let networkInfoFetcher: NetworkInfoFetcher
        private let userDataProvider: UserDataProviderProtocol
        private let identifier: UInt64
        
        init(
            pendingOffersRepo: PendingOffersRepo,
            transactionSender: TransactionSender,
            amountConverter: AmountConverterProtocol,
            amountPrecision: Int,
            networkInfoFetcher: NetworkInfoFetcher,
            userDataProvider: UserDataProviderProtocol,
            identifier: UInt64
            ) {
            
            self.pendingOffersRepo = pendingOffersRepo
            self.transactionSender = transactionSender
            self.amountConverter = amountConverter
            self.amountPrecision = amountPrecision
            self.networkInfoFetcher = networkInfoFetcher
            self.userDataProvider = userDataProvider
            self.identifier = identifier
        }
        
        private func getSectionsForOffer(
            _ offer: PendingOffersRepo.Offer
            ) -> [TransactionDetails.Model.SectionModel] {
            
            let dateFormatter = TransactionDetails.DateFormatter()
            let amountFormatter = TransactionDetails.AmountFormatter()
            
            let stateCell = TransactionDetails.Model.CellModel(
                title: "State",
                value: "Investment",
                identifier: "stateCell"
            )
            let stateSection = TransactionDetails.Model.SectionModel(
                title: "",
                cells: [stateCell],
                description: ""
            )
            
            let toPay: Model.Amount = Model.Amount(
                value: offer.quoteAmount + offer.fee,
                asset: offer.quoteAssetCode
            )
            let toPayCell = TransactionDetails.Model.CellModel(
                title: "Paid",
                value: amountFormatter.formatAmount(toPay),
                identifier: "toPayCell"
            )
            let toPayAmount: Model.Amount = Model.Amount(
                value: offer.quoteAmount,
                asset: offer.quoteAssetCode
            )
            let toPayAmountCell = TransactionDetails.Model.CellModel(
                title: "Amount",
                value: amountFormatter.formatAmount(toPayAmount),
                identifier: "toPayAmountCell"
            )
            let toPayFee: Model.Amount = Model.Amount(
                value: offer.fee,
                asset: offer.quoteAssetCode
            )
            let toPayFeeCell = TransactionDetails.Model.CellModel(
                title: "Fee",
                value: amountFormatter.formatAmount(toPayFee),
                identifier: "toPayFeeCell"
            )
            let toPaySection = TransactionDetails.Model.SectionModel(
                title: "",
                cells: [toPayCell, toPayAmountCell, toPayFeeCell],
                description: ""
            )
            
            let toReceive: Model.Amount = Model.Amount(
                value: offer.baseAmount,
                asset: offer.baseAssetCode
            )
            let toReceiveCell = TransactionDetails.Model.CellModel(
                title: "Received",
                value: amountFormatter.formatAmount(toReceive),
                identifier: "toReceiveCell"
            )
            let toReceivePrice: Model.Amount = Model.Amount(
                value: offer.quoteAmount / offer.baseAmount,
                asset: offer.quoteAssetCode
            )
            let toReceiveBase: Model.Amount = Model.Amount(
                value: 1,
                asset: offer.baseAssetCode
            )
            let toReceiveBaseAmount = amountFormatter.formatAmount(toReceiveBase)
            let toReceivePriceAmount = amountFormatter.formatAmount(toReceivePrice)
            let toReceivePriceCellValue = "\(toReceiveBaseAmount) for \(toReceivePriceAmount)"
            let toReceivePriceCell = TransactionDetails.Model.CellModel(
                title: "Price",
                value: toReceivePriceCellValue,
                identifier: "toReceivePriceCell"
            )
            let toReceivedSection = TransactionDetails.Model.SectionModel(
                title: "",
                cells: [toReceiveCell, toReceivePriceCell],
                description: ""
            )
            
            let dateCell = TransactionDetails.Model.CellModel(
                title: "Date",
                value: dateFormatter.dateToString(date: offer.createdAt),
                identifier: "dateCell"
            )
            let dateSection = TransactionDetails.Model.SectionModel(
                title: "",
                cells: [dateCell],
                description: ""
            )
            return [stateSection, toPaySection, toReceivedSection, dateSection]
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
        
        var title: String {
            switch self {
            case .cancel:
                return "Cancel"
            }
        }
    }
    
    func getActions() -> [TransactionDetailsProviderProtocol.Action] {
        let actions: [PendingOfferAction] = [.cancel]
        
        return actions.map({ (action) -> TransactionDetailsProviderProtocol.Action in
            return TransactionDetailsProviderProtocol.Action(
                id: action.rawValue,
                title: action.title
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
                onError("Failed to decode base balance id")
                onHideLoading()
                return
        }
        
        guard let quoteBalanceId = BalanceID(
            base32EncodedString: offer.quoteBalanceId,
            expectedVersion: .balanceIdEd25519
            ) else {
                onError("Failed to decode quote balance id")
                onHideLoading()
                return
        }
        
        let operation = ManageOfferOp(
            baseBalance: baseBalanceId,
            quoteBalance: quoteBalanceId,
            isBuy: offer.isBuy,
            amount: 0,
            price: self.amountConverter.convertDecimalToInt64(value: offer.price, precision: self.amountPrecision),
            fee: self.amountConverter.convertDecimalToInt64(value: offer.fee, precision: self.amountPrecision),
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
