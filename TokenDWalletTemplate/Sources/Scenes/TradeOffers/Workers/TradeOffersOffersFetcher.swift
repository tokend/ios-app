import Foundation
import TokenDSDK

extension TradeOffers {
    
    public class OffersFetcher {
        
        private let orderBookApi: TokenDSDK.OrderBookApi
        private var offersCancelables: [Cancelable] = []
        private var tradesCancelables: [Cancelable] = []
        
        public init(
            orderBookApi: TokenDSDK.OrderBookApi
            ) {
            
            self.orderBookApi = orderBookApi
        }
    }
}

extension TradeOffers.OffersFetcher: TradeOffers.OffersFetcherProtocol {
    
    public func getOffers(
        forBuy: Bool,
        base: String,
        quote: String,
        limit: Int,
        cursor: String?,
        completion: @escaping (OffersFetchResult) -> Void
        ) {
        
        let parameters = OrderBookRequestParameters(
            isBuy: forBuy,
            baseAsset: base,
            quoteAsset: quote
        )
        
        let token = self.orderBookApi.requestOrderBook(
            parameters: parameters,
            limit: limit,
            cursor: cursor,
            completion: { (result) in
                switch result {
                    
                case .success(let offersResponse):
                    let offers = offersResponse.map({ (offer) -> TradeOffers.Model.Offer in
                        return offer.offer
                    })
                    completion(.succeeded(offers))
                    
                case .failure:
                    completion(.failed)
                }
        })
        
        self.offersCancelables.append(token)
    }
    
    public func cancelOffersRequests() {
        for token in self.offersCancelables {
            token.cancel()
        }
    }
    
    public func getTrades(
        base: String,
        quote: String,
        limit: Int,
        cursor: String?,
        completion: @escaping (TradesFetchResult) -> Void
        ) {
        
        let parameters = TradesRequestParameters(
            baseAsset: base,
            quoteAsset: quote,
            orderBookId: "0"
        )
        
        let token = self.orderBookApi.requestTrades(
            parameters: parameters,
            limit: limit,
            cursor: cursor,
            completion: { (result) in
                switch result {
                    
                case .success(let tradesResponse):
                    let trades = tradesResponse.map({ (trade) -> TradeOffers.Model.Trade in
                        return trade.trade
                    })
                    completion(.succeeded(trades))
                    
                case .failure:
                    completion(.failed)
                }
        })
        
        self.offersCancelables.append(token)
    }
    
    public func cancelTradesRequests() {
        for token in self.tradesCancelables {
            token.cancel()
        }
    }
}

extension OrderBookResponse {
    fileprivate typealias Model = TradeOffers.Model
    fileprivate typealias Amount = Model.Amount
    fileprivate typealias Offer = Model.Offer
    
    fileprivate var offer: Offer {
        let amount = Amount(
            value: self.baseAmount,
            currency: self.baseAssetCode
        )
        let price = Amount(
            value: self.price,
            currency: self.quoteAssetCode
        )
        
        return Model.Offer(
            amount: amount,
            price: price,
            isBuy: self.isBuy
        )
    }
}

extension TradeResponse {
    fileprivate typealias Model = TradeOffers.Model
    fileprivate typealias Trade = Model.Trade
    
    fileprivate var trade: Trade {
        return Trade(
            amount: self.baseAmount,
            price: self.price,
            date: self.createdAt
        )
    }
}
