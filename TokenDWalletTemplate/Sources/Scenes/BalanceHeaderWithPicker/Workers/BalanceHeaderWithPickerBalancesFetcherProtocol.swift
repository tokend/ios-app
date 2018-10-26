import Foundation
import RxCocoa
import RxSwift

protocol BalanceHeaderWithPickerBalancesFetcherProtocol {
    typealias HeaderBalance = BalanceHeaderWithPicker.Model.Balance
    
    var headerBalances: [HeaderBalance] { get }
    
    func observeHeaderBalances() -> Observable<[HeaderBalance]>
}

extension BalanceHeaderWithPicker {
    typealias BalancesFetcherProtocol = BalanceHeaderWithPickerBalancesFetcherProtocol
}
