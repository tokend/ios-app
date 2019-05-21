import Foundation
import TokenDSDK
import TokenDWallet

enum SaleInvestCancelInvestResult {
    case failure(String)
    case success
}
protocol SaleInvestCancelInvestWorkerProtocol {
    func cancelInvest(
        model: SaleInvest.Model.CancelInvestModel,
        completion: @escaping ((SaleInvestCancelInvestResult) -> Void)
    )
}

extension SaleInvest {
    typealias CancelInvestWorkerProtocol = SaleInvestCancelInvestWorkerProtocol
    
    class CancelInvestWorker {
        
        // MARK: - Private properties
        
        private let transactionSender: TransactionSender
        private let amountConverter: AmountConverterProtocol
        private let networkInfoFetcher: NetworkInfoFetcher
        private let userDataProvider: UserDataProviderProtocol
        
        // MARK: -
        
        init(
            transactionSender: TransactionSender,
            amountConverter: AmountConverterProtocol,
            networkInfoFetcher: NetworkInfoFetcher,
            userDataProvider: UserDataProviderProtocol
            ) {
            
            self.transactionSender = transactionSender
            self.amountConverter = amountConverter
            self.networkInfoFetcher = networkInfoFetcher
            self.userDataProvider = userDataProvider
        }
        
        // MARK: - Private
        
        private func cancelInvestment(
            cancelModel: SaleInvest.Model.CancelInvestModel,
            networkInfo: NetworkInfoModel,
            completion: @escaping ((SaleDetailsCancelInvestResult) -> Void)
            ) {
            
            guard let baseBalanceId = BalanceID(
                base32EncodedString: cancelModel.baseBalance,
                expectedVersion: .balanceIdEd25519
                ) else {
                    completion(.failure(Localized(.failed_to_decode_base_balance_id)))
                    return
            }
            
            guard let quoteBalanceId = BalanceID(
                base32EncodedString: cancelModel.quoteBalance,
                expectedVersion: .balanceIdEd25519
                ) else {
                    completion(.failure(Localized(.failed_to_decode_quote_balance_id)))
                    return
            }
            
            let price = self.amountConverter.convertDecimalToInt64(
                value: cancelModel.price,
                precision: networkInfo.precision
            )
            
            let fee = self.amountConverter.convertDecimalToInt64(
                value: cancelModel.fee,
                precision: networkInfo.precision
            )
            
            let operation = ManageOfferOp(
                baseBalance: baseBalanceId,
                quoteBalance: quoteBalanceId,
                isBuy: true,
                amount: 0,
                price: price,
                fee: fee,
                offerID: cancelModel.prevOfferId,
                orderBookID: Uint64(cancelModel.orderBookId),
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
            
            guard let transaction = try? transactionBuilder.buildTransaction() else {
                completion(.failure(Localized(.failed_to_build_transaction)))
                return
            }
            
            try? self.transactionSender.sendTransaction(
                transaction,
                walletId: self.userDataProvider.walletId,
                completion: { (result) in
                    
                    switch result {
                        
                    case .succeeded:
                        completion(.success)
                        
                    case .failed(let error):
                        completion(.failure(error.localizedDescription))
                    }
            })
        }
    }
}

extension SaleInvest.CancelInvestWorker: SaleDetails.CancelInvestWorkerProtocol {
    
    func cancelInvest(
        model: SaleInvest.Model.CancelInvestModel,
        completion: @escaping ((SaleInvestCancelInvestResult) -> Void)
        ) {
        
        self.networkInfoFetcher.fetchNetworkInfo { [weak self] (result) in
            switch result {
                
            case .succeeded(let networkInfo):
                self?.cancelInvestment(
                    cancelModel: model,
                    networkInfo: networkInfo,
                    completion: completion
                )
                
            case .failed(let error):
                completion(.failure(error.localizedDescription))
            }
        }
    }
}
