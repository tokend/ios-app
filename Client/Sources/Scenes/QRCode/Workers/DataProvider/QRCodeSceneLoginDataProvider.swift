import Foundation
import RxSwift
import RxCocoa

extension QRCodeScene {
    
    class LoginDataProvider {
        
        // MARK: Private properties
        
        private let loginBehaviorRelay: BehaviorRelay<String>
        private let userDataProvider: UserDataProviderProtocol
        
        // MARK:
        
        init(
            userDataProvider: UserDataProviderProtocol
        ) {
            
            self.userDataProvider = userDataProvider
            self.loginBehaviorRelay = .init(
                value: userDataProvider.userLogin
            )
        }
    }
}

extension QRCodeScene.LoginDataProvider: QRCodeScene.DataProviderProtocol {
    
    var data: String {
        loginBehaviorRelay.value
    }
    
    var title: String {
        "Login"
    }
    
    func observeData() -> Observable<String> {
        loginBehaviorRelay.asObservable()
    }
}
