import UIKit
import LocalAuthentication
import RxSwift
import RxCocoa
import TokenDSDK

protocol SaleInvestDataProviderProtocol {
    func observeSale() -> Observable<SaleInvest.Model.SaleModel?>
    func observeAsset(assetCode: String) -> Observable<SaleInvest.Model.AssetModel?>
    func observeBalances() -> Observable<[SaleInvest.Model.BalanceDetails]>
    func observeOffers() -> Observable<[SaleInvest.Model.InvestmentOffer]>
    func observeErrors() -> Observable<Swift.Error>
    
    func refreshBalances()
}

extension SaleInvest {
    typealias DataProvider = SaleInvestDataProviderProtocol
    
    class SaleInvestProvider: DataProvider {
        
        // MARK: - Private properties
        
        private let saleIdentifier: String
        private let salesRepo: SalesRepo
        private let assetsRepo: AssetsRepo
        private let balancesRepo: BalancesRepo
        private let offersRepo: PendingOffersRepo
        
        private let pendingOffers: BehaviorRelay<[PendingOffersRepo.Offer]> = BehaviorRelay(value: [])
        
        private let errors: PublishRelay<Swift.Error> = PublishRelay()
        
        // MARK: -
        
        init(
            saleIdentifier: String,
            salesRepo: SalesRepo,
            assetsRepo: AssetsRepo,
            balancesRepo: BalancesRepo,
            walletRepo: WalletRepo,
            offersRepo: PendingOffersRepo
            ) {
            
            self.saleIdentifier = saleIdentifier
            self.salesRepo = salesRepo
            self.assetsRepo = assetsRepo
            self.balancesRepo = balancesRepo
            self.offersRepo = offersRepo
        }
        
        // MARK: - SectionsProvider
        
        func observeSale() -> Observable<Model.SaleModel?> {
            return self.salesRepo.observeSale(id: self.saleIdentifier).map({ [weak self] (sale) -> Model.SaleModel? in
                guard let sale = sale else {
                    return nil
                }
                
                let quoteAssets: [Model.SaleModel.QuoteAsset] = sale.quoteAssets.quoteAssets.map({ quoteAsset in
                    return Model.SaleModel.QuoteAsset(
                        asset: quoteAsset.asset,
                        currentCap: quoteAsset.currentCap,
                        price: quoteAsset.price,
                        quoteBalanceId: quoteAsset.quoteBalanceId
                    )
                })
                
                let saleModel = Model.SaleModel(
                    id: sale.id,
                    baseAsset: sale.baseAsset,
                    baseAssetName: sale.details.name,
                    defaultQuoteAsset: sale.defaultQuoteAsset,
                    type: sale.saleType.value,
                    ownerId: sale.ownerId,
                    quoteAssets: quoteAssets
                )
                
                self?.loadPendingOffers(saleId: saleModel.id)
                return saleModel
            })
        }
        
        func observeBalances() -> Observable<[Model.BalanceDetails]> {
            return self.balancesRepo.observeBalancesDetails().map { (balances) -> [Model.BalanceDetails] in
                return balances.compactMap({ (balanceState) -> BalancesRepo.BalanceDetails? in
                    switch balanceState {
                        
                    case .creating:
                        return nil
                        
                    case .created(let balance):
                        return balance
                    }
                }).map({ (balance) -> Model.BalanceDetails in
                    return Model.BalanceDetails(
                        asset: balance.asset,
                        balance: balance.balance,
                        balanceId: balance.balanceId,
                        prevOfferId: nil
                    )
                })
            }
        }
        
        func observeOffers() -> Observable<[Model.InvestmentOffer]> {
            self.offersRepo.reloadOffers()
            self.loadPendingOffers(saleId: self.saleIdentifier)
            
            return self.pendingOffers.map({ (offers) -> [Model.InvestmentOffer] in
                return offers.map({ (offer) -> Model.InvestmentOffer in
                    return Model.InvestmentOffer(
                        amount: offer.quoteAmount,
                        asset: offer.quoteAssetCode,
                        id: offer.offerId
                    )
                })
            }).asObservable()
        }
        
        func observeAsset(assetCode: String) -> Observable<Model.AssetModel?> {
            return self.assetsRepo.observeAsset(code: assetCode).map({ (asset) -> Model.AssetModel? in
                guard let asset = asset else {
                    return nil
                }
                let assetModel = Model.AssetModel(
                    code: asset.code
                )
                
                return assetModel
            })
        }
        
        func observeErrors() -> Observable<Swift.Error> {
            return self.errors.asObservable()
        }
        
        func refreshBalances() {
            self.balancesRepo.reloadBalancesDetails()
        }
        
        // MARK: - Private
        
        private func loadPendingOffers(saleId: String) {
            let parameters = OffersOffersRequestParameters(
                isBuy: true,
                order: nil,
                baseAsset: nil,
                quoteAsset: nil,
                orderBookId: saleId,
                offerId: nil
            )
            
            self.offersRepo.loadOffers(
                parameters: parameters,
                completion: { [weak self] (result) in
                    switch result {
                        
                    case .failure(let error):
                        self?.errors.accept(error)
                        
                    case .success(let offers):
                        self?.pendingOffers.accept(offers)
                    }
            })
        }
    }
}
