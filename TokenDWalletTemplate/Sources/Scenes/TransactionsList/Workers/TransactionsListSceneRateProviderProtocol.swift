import Foundation
import RxCocoa
import RxSwift

protocol TransactionsListSceneRateProviderProtocol {
    
    var rate: Observable<Void> { get }
    
    func rateForAmount(
        _ amount: Decimal,
        ofAsset asset: String,
        destinationAsset: String
        ) -> Decimal?
}

extension TransactionsListScene {
    typealias RateProviderProtocol = TransactionsListSceneRateProviderProtocol
}

extension RateProvider: TransactionsListScene.RateProviderProtocol { }
