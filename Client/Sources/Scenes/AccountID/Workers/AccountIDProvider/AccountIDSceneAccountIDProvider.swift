import Foundation
import RxSwift
import RxCocoa

extension AccountIDScene {
    
    class AccountIDProvider {
        
        // MARK: Private properties
        
        private let accountIdBehaviorRelay: BehaviorRelay<String>
        private let userDataProvider: UserDataProviderProtocol
        
        // MARK:
        
        init(
            userDataProvider: UserDataProviderProtocol
        ) {
            
            self.userDataProvider = userDataProvider
            accountIdBehaviorRelay = .init(value: userDataProvider.walletData.accountId)
        }
    }
}

extension AccountIDScene.AccountIDProvider: AccountIDScene.AccountIDProviderProtocol {
    
    var accountId: String {
        accountIdBehaviorRelay.value
    }
    
    func observeAccountId() -> Observable<String> {
        accountIdBehaviorRelay.asObservable()
    }
}
