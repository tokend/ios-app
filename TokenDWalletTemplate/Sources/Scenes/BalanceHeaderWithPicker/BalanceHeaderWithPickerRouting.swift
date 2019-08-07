import Foundation

extension BalanceHeaderWithPicker {
    struct Routing {
        typealias DidSelectAsset = (String) -> Void
        
        let onDidSelectAsset: DidSelectAsset
    }
}
