import Foundation
import RxSwift
import RxCocoa

extension QRCodeScene {
    
    class AccountIDDataProvider {
        
        // MARK: Private properties
        
        private let accountIdBehaviorRelay: BehaviorRelay<String>
        private let userDataProvider: UserDataProviderProtocol
        
        // MARK:
        
        init(
            userDataProvider: UserDataProviderProtocol
        ) {
            
            self.userDataProvider = userDataProvider
            accountIdBehaviorRelay = .init(value: userDataProvider.walletData.accountId.uppercased())
        }
    }
}

extension QRCodeScene.AccountIDDataProvider: QRCodeScene.DataProviderProtocol {
    
    var data: String {
        accountIdBehaviorRelay.value
    }
    
    var title: String {
        "Account ID"
    }
    
    func observeData() -> Observable<String> {
        accountIdBehaviorRelay.asObservable()
    }
}
