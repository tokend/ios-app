import UIKit
import RxCocoa
import RxSwift
import TokenDSDK

struct TransactionDetailsProviderAction {
    let id: String
    let icon: UIImage
    let title: String
    let message: String
}

protocol TransactionDetailsProviderProtocol {
    typealias Action = TransactionDetailsProviderAction
    
    func observeTransaction() -> Observable<[TransactionDetails.Model.SectionModel]>
    func getActions() -> [Action]
    func performActionWithId(
        _ id: String,
        onSuccess: @escaping () -> Void,
        onShowLoading: @escaping () -> Void,
        onHideLoading: @escaping () -> Void,
        onError: @escaping (String) -> Void
    )
}

extension TransactionDetails {
    typealias SectionsProviderProtocol = TransactionDetailsProviderProtocol
}
