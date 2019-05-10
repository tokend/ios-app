import Foundation
import DLJSONAPI
import RxCocoa
import RxSwift
import TokenDSDK

extension TradeOffers {
    
    public class OffersFetcher {
        
        public typealias OrderBook = TradeOffers.Model.OrderBook
        
        // MARK: - Private properties
        
        private let orderBookApiV3: TokenDSDK.OrderBookApiV3
        private let baseAsset: String
        private let quoteAsset: String
        private let pendingOffersRepo: PendingOffersRepo
        
        private var pageSize: Int = 10
        private var cancelable: TokenDSDK.Cancelable?
        
        private let orderBook: BehaviorRelay<OrderBook> =
            BehaviorRelay(value: OrderBook(buyItems: [], sellItems: []))
        private let loadingStatus: BehaviorRelay<LoadingStatus> = BehaviorRelay(value: .loaded)
        private let errorStatus: PublishRelay<Swift.Error> = PublishRelay()
        
        private let disposeBag = DisposeBag()
        
        // MARK: -
        
        public init(
            orderBookApiV3: TokenDSDK.OrderBookApiV3,
            baseAsset: String,
            quoteAsset: String,
            pendingOffersRepo: PendingOffersRepo
            ) {
            
            self.orderBookApiV3 = orderBookApiV3
            self.baseAsset = baseAsset
            self.quoteAsset = quoteAsset
            self.pendingOffersRepo = pendingOffersRepo
        }
        
        // MARK: - Private
        
        private func loadOffers(pageSize: Int) {
            self.pageSize = pageSize
            
            self.loadingStatus.accept(.loading)
            
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                self.cancelable = self.orderBookApiV3.requestOffers(
                    baseAsset: self.baseAsset,
                    quoteAsset: self.quoteAsset,
                    orderBookId: "0",
                    maxEntries: pageSize,
                    include: self.orderBookApiV3.requestBuilder.offersIncludeAll,
                    completion: { [weak self] (result) in
                        self?.loadingStatus.accept(.loaded)
                        
                        switch result {
                            
                        case .failure(let error):
                            self?.errorStatus.accept(error)
                            
                        case .success(let document):
                            self?.onItemsLoaded(resource: document.data)
                        }
                })
            })
        }
        
        private func reloadOffers() {
            guard self.getLoadingStatusValue() == .loaded else {
                return
            }
            
            self.loadOffers(pageSize: self.pageSize)
        }
        
        private func onItemsLoaded(resource: OrderBookResource?) {
            let buyItems = self.mapItems(resource?.buyEntries)
            let sellItems = self.mapItems(resource?.sellEntries)
            
            self.orderBook.accept(OrderBook(buyItems: buyItems, sellItems: sellItems))
        }
        
        private func mapItems(_ items: [OrderBookEntryResource]?) -> [Model.Offer] {
            guard let items = items else {
                return []
            }
            
            let models: [Model.Offer] = items.compactMap { (item) -> Model.Offer? in
                return item.offer
            }
            
            return models
        }
    }
}

extension TradeOffers.OffersFetcher: TradeOffers.OffersFetcherProtocol {
    
    public func getOrderBookValue() -> OrderBook {
        return self.orderBook.value
    }
    
    public func getLoadingStatusValue() -> LoadingStatus {
        return self.loadingStatus.value
    }
    
    public func observeOrderBook(pageSize: Int) -> Observable<OrderBook> {
        self.loadOffers(pageSize: pageSize)
        
        self.pendingOffersRepo.observeOffers()
            .subscribe(onNext: { [weak self] _ in
                self?.reloadOffers()
            })
            .disposed(by: self.disposeBag)
        
        return self.orderBook.asObservable()
    }
    
    public func reloadOrderBook() {
        self.reloadOffers()
    }
    
    public func observeLoadingStatus() -> Observable<LoadingStatus> {
        return self.loadingStatus.asObservable()
    }
    
    public func observeErrorStatus() -> Observable<Swift.Error> {
        return self.errorStatus.asObservable()
    }
}

extension OrderBookEntryResource {
    fileprivate typealias Model = TradeOffers.Model
    fileprivate typealias Amount = Model.Amount
    fileprivate typealias Offer = Model.Offer
    
    fileprivate var offer: Offer? {
        guard
            let baseAsset = self.baseAsset?.id,
            let quoteAsset = self.quoteAsset?.id else {
                return nil
        }
        
        let amount = Amount(
            value: self.cumulativeBaseAmount,
            currency: baseAsset
        )
        let price = Amount(
            value: self.price,
            currency: quoteAsset
        )
        
        return Model.Offer(
            amount: amount,
            price: price,
            volume: self.cumulativeBaseAmount,
            isBuy: self.isBuy
        )
    }
}
