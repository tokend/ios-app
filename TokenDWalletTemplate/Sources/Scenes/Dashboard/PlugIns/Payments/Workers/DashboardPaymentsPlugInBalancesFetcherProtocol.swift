import Foundation
import RxCocoa
import RxSwift

protocol DashboardPaymentsPlugInBalancesFetcherProtocol {
    typealias PaymentsPreviewBalance = DashboardPaymentsPlugIn.Model.Balance
    typealias LoadingStatus = DashboardPaymentsPlugIn.Model.LoadingStatus
    
    var paymentsPreviewBalances: [PaymentsPreviewBalance] { get }
    
    func observePaymentsPreviewBalances() -> Observable<[PaymentsPreviewBalance]>
}

extension DashboardPaymentsPlugIn {
    typealias BalancesFetcherProtocol = DashboardPaymentsPlugInBalancesFetcherProtocol
}
