import Foundation
import TokenDSDK
import TokenDWallet
import RxSwift
import RxCocoa

extension ConfirmationScene {
    class ConfirmationSectionsProviderDummy {
        
        // MARK: - Private properties
        
        private let sectionsRelay: BehaviorRelay<[ConfirmationScene.Model.SectionModel]> = BehaviorRelay(value: [])
        
        // MARK: -
        private let transactionSender: TransactionSender
        private let userDataProvider: UserDataProviderProtocol
        
        init(
            transactionSender: TransactionSender,
            userDataProvider: UserDataProviderProtocol
            ) {
            
            self.transactionSender = transactionSender
            self.userDataProvider = userDataProvider
        }
    }
}

extension ConfirmationScene.ConfirmationSectionsProviderDummy: ConfirmationScene.SectionsProvider {
    func observeConfirmationSections() -> Observable<[ConfirmationScene.Model.SectionModel]> {
        return self.sectionsRelay.asObservable()
    }
    
    func loadConfirmationSections() {
        let textCell = ConfirmationScene.Model.CellModel(
            title: "Text test",
            cellType: .text(value: "Some text"),
            identifier: "textTest"
        )
        let textSection = ConfirmationScene.Model.SectionModel(cells: [textCell])
        
        let boolCell = ConfirmationScene.Model.CellModel(
            title: "Bool test",
            cellType: .boolSwitch(value: true),
            identifier: "boolTest"
        )
        let boolSection = ConfirmationScene.Model.SectionModel(cells: [boolCell])
        
        let textEditCell = ConfirmationScene.Model.CellModel(
            title: "Text Edit test",
            cellType: .textField(value: nil, placeholder: "Enter text", maxCharacters: 100),
            identifier: "textEditTest"
        )
        let textEditSection = ConfirmationScene.Model.SectionModel(cells: [textEditCell])
        
        self.sectionsRelay.accept([
            textSection,
            boolSection,
            textEditSection
            ]
        )
    }
    
    func handleTextEdit(
        identifier: ConfirmationScene.CellIdentifier,
        value: String?
        ) {
        
    }
    
    func handleBoolSwitch(
        identifier: ConfirmationScene.CellIdentifier,
        value: Bool
        ) {
        
    }
    
    func handleConfirmAction(completion: @escaping (_ result: ConfirmationResult) -> Void) {
        completion(.failed(.notEnoughData))
        
    }
}
