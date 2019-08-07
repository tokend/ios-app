import Foundation
import TokenDSDK

extension Trade {
    class OffersFetcher {
        
        private let orderBookApi: TokenDSDK.OrderBookApi
        private var cancellableTokens: [CancellableToken] = []
        
        init(
            orderBookApi: TokenDSDK.OrderBookApi
            ) {
            
            self.orderBookApi = orderBookApi
        }
    }
}

extension Trade.OffersFetcher: Trade.OffersFetcherProtocol {
    func getOffers(
        forBuy: Bool,
        base: String,
        quote: String,
        completion: @escaping (TradeOffersFetchResult) -> Void
        ) {
        
        let parameters = OrderBookRequestParameters(
            isBuy: forBuy,
            baseAsset: base,
            quoteAsset: quote
        )
        
        let token = self.orderBookApi.requestOrderBook(
            parameters: parameters,
            completion: { (result) in
                switch result {
                    
                case .success(let offersResponse):
                    let offers = offersResponse.map({ (offer) -> Trade.Model.Offer in
                        return offer.offer
                    })
                    completion(.succeeded(offers))
                    
                case .failure:
                    completion(.failed)
                }
        })
        
        self.cancellableTokens.append(token)
    }
    
    func cancelRequests() {
        for token in self.cancellableTokens {
            token.cancel()
        }
    }
}

extension OrderBookResponse {
    typealias Model = Trade.Model
    typealias Amount = Model.Amount
    typealias Offer = Model.Offer
    
    fileprivate var offer: Offer {
        let amount = Amount(
            value: self.baseAmount,
            currency: self.baseAssetCode
        )
        let price = Amount(
            value: self.price,
            currency: self.quoteAssetCode
        )
        
        return Trade.Model.Offer(
            amount: amount,
            price: price,
            isBuy: self.isBuy
        )
    }
}
