import Foundation
import RxSwift
import RxCocoa

extension SendAssetScene {
    class RecipientProvider {
        
        // MARK: - Private properties
        
        private let recipientAddressBehaviorRelay: BehaviorRelay<String?> = .init(value: nil)
        
        // MARK: - Public methods
        
        public func setRecipientAddress(value: String) {
            recipientAddressBehaviorRelay.accept(value)
        }
    }
}

extension SendAssetScene.RecipientProvider: SendAssetScene.RecipientProviderProtocol {
    
    var recipientAddress: String? {
        recipientAddressBehaviorRelay.value
    }
    
    func observeRecipientAddress() -> Observable<String?> {
        return recipientAddressBehaviorRelay.asObservable()
    }
} 
