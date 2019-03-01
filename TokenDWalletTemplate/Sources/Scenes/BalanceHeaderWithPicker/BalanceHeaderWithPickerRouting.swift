import Foundation

extension BalanceHeaderWithPicker {
    struct Routing {
        typealias DidSelectBalance = (_ balance: String?, _ asset: String) -> Void
        
        let onDidSelectBalance: DidSelectBalance
    }
}
