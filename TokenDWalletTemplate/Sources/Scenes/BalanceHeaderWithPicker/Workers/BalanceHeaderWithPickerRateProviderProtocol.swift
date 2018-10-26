import Foundation
import RxSwift
import RxCocoa

protocol BalanceHeaderWithPickerRateProviderProtocol {
    
    var rate: Observable<Void> { get }
    
    func rateForAmount(
        _ amount: Decimal,
        ofAsset asset: String,
        destinationAsset: String
        ) -> Decimal?
}

extension BalanceHeaderWithPicker {
    typealias RateProviderProtocol = BalanceHeaderWithPickerRateProviderProtocol
}

extension RateProvider: BalanceHeaderWithPicker.RateProviderProtocol { }
