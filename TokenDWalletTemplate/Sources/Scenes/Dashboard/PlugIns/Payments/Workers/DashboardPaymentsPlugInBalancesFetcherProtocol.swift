import Foundation
import RxCocoa
import RxSwift

protocol DashboardPaymentsPlugInBalancesFetcherProtocol {
    typealias PaymentsPreviewBalance = DashboardPaymentsPlugIn.Model.Balance
    typealias LoadingStatus = DashboardPaymentsPlugIn.Model.LoadingStatus
    
    var paymentsPreviewBalances: [PaymentsPreviewBalance] { get }
    
    func observePaymentsPreviewBalances() -> Observable<[PaymentsPreviewBalance]>
    func refreshPaymentsPreviewBalances()
}

extension DashboardPaymentsPlugIn {
    typealias BalancesFetcherProtocol = DashboardPaymentsPlugInBalancesFetcherProtocol
}
