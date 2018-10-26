import UIKit
import RxSwift
import RxCocoa

enum ConfirmationResult {
    case failed(ConfirmationScene.Event.ConfirmAction.ConfirmError)
    case succeeded
}

protocol ConfirmationSectionsProviderProtocol {
    func observeConfirmationSections() -> Observable<[ConfirmationScene.Model.SectionModel]>
    func loadConfirmationSections()
    
    func handleTextEdit(
        identifier: ConfirmationScene.CellIdentifier,
        value: String?
    )
    
    func handleBoolSwitch(
        identifier: ConfirmationScene.CellIdentifier,
        value: Bool
    )
    
    func handleConfirmAction(completion: @escaping (_ result: ConfirmationResult) -> Void)
}
