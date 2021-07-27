import Foundation
import RxSwift
import RxCocoa

extension MoreScene {
    
    class UserDataProvider {
        
        // MARK: Private properties
        
        private let userDataBehaviorRelay: BehaviorRelay<MoreScene.Model.UserData?>
        private let loginBehaviorRelay: BehaviorRelay<String>
        private let accountTypeBehaviorRelay: BehaviorRelay<AccountType>
        
        private let userDataProvider: Client.UserDataProviderProtocol
        private let accountTypeManager: AccountTypeManagerProtocol
        
        private let disposeBag: DisposeBag = .init()
        
        private var shouldObserveAccountType: Bool = true
        
        // MARK:

        init(
            userDataProvider: Client.UserDataProviderProtocol,
            accountTypeManager: AccountTypeManagerProtocol
        ) {
            
            self.userDataProvider = userDataProvider
            self.accountTypeManager = accountTypeManager
            
            loginBehaviorRelay = .init(value: userDataProvider.userLogin)
            accountTypeBehaviorRelay = .init(value: accountTypeManager.accountType)
            
            userDataBehaviorRelay = .init(
                value: nil
//                value: .init(
//                    avatarUrl: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/Hammond_Slides_Russia_20.jpg/305px-Hammond_Slides_Russia_20.jpg")!,
//                    name: "Yehor",
//                    surname: "Miroshnychenko"
//                )
            )
        }
    }
}

// MARK: Private methods

private extension MoreScene.UserDataProvider {
    
    func observeAccountTypeManagerIfNeeded() {
        
        guard shouldObserveAccountType
        else {
            return
        }
        
        shouldObserveAccountType = false
        
        accountTypeManager
            .observeAccountType()
            .subscribe(onNext: { [weak self] (accountType) in
                self?.accountTypeBehaviorRelay.accept(accountType)
            })
            .disposed(by: disposeBag)
    }
}

extension MoreScene.UserDataProvider: MoreScene.UserDataProviderProtocol {
    
    var userData: MoreScene.Model.UserData? {
        userDataBehaviorRelay.value
    }
    
    var login: String {
        loginBehaviorRelay.value
    }
    
    var accountType: AccountType {
        observeAccountTypeManagerIfNeeded()
        return accountTypeBehaviorRelay.value
    }
    
    func observeLogin() -> Observable<String> {
        loginBehaviorRelay.asObservable()
    }
    
    func observeUserData() -> Observable<MoreScene.Model.UserData?> {
        userDataBehaviorRelay.asObservable()
    }
    
    func observeAccountType() -> Observable<AccountType> {
        observeAccountTypeManagerIfNeeded()
        return accountTypeBehaviorRelay.asObservable()
    }
}
