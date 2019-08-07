import Foundation
import RxSwift
import RxCocoa

protocol DashboardPaymentsPlugInRateProviderProtocol {
    
    var rate: Observable<Void> { get }
    
    func rateForAmount(
        _ amount: Decimal,
        ofAsset asset: String,
        destinationAsset: String
        ) -> Decimal?
}

extension DashboardPaymentsPlugIn {
    typealias RateProviderProtocol = DashboardPaymentsPlugInRateProviderProtocol
}

extension RateProvider: DashboardPaymentsPlugIn.RateProviderProtocol { }
