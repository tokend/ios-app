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
