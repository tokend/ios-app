import Foundation
import RxSwift
import RxCocoa

extension MoreScene {
    
    class UserDataProvider {
        
        // MARK: Private properties
        
        private let userDataBehaviorRelay: BehaviorRelay<MoreScene.Model.UserType?>
        private let loginBehaviorRelay: BehaviorRelay<String>
        private let accountTypeBehaviorRelay: BehaviorRelay<AccountType>
        
        private let userDataProvider: Client.UserDataProviderProtocol
        private let accountTypeManager: AccountTypeManagerProtocol
        private let activeKYCRepo: ActiveKYCRepo
        private let imagesUtility: ImagesUtility
        
        private let disposeBag: DisposeBag = .init()
        
        private var shouldObserveAccountType: Bool = true
        private var shouldObserveActiveKYC: Bool = true
        
        // MARK:

        init(
            userDataProvider: Client.UserDataProviderProtocol,
            accountTypeManager: AccountTypeManagerProtocol,
            activeKYCRepo: ActiveKYCRepo,
            imagesUtility: ImagesUtility
        ) {
            
            self.userDataProvider = userDataProvider
            self.accountTypeManager = accountTypeManager
            self.activeKYCRepo = activeKYCRepo
            self.imagesUtility = imagesUtility
            
            loginBehaviorRelay = .init(value: userDataProvider.userLogin)
            accountTypeBehaviorRelay = .init(value: accountTypeManager.accountType)
            
            userDataBehaviorRelay = .init(
                value: nil
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
    
    func observeActiveKYCRepoIfNeeded() {
        
        guard shouldObserveActiveKYC
        else {
            return
        }
        
        shouldObserveActiveKYC = false
        
        activeKYCRepo
            .observeActiveKYC()
            .subscribe(onNext: { [weak self] (kyc) in
                
                guard let imagesUtility = self?.imagesUtility
                else {
                    return
                }
                
                self?.userDataBehaviorRelay.accept(kyc.mapToUserData(imagesUtility: imagesUtility))
            })
            .disposed(by: disposeBag)
    }
}

extension MoreScene.UserDataProvider: MoreScene.UserDataProviderProtocol {
    
    var userData: MoreScene.Model.UserType? {
        observeActiveKYCRepoIfNeeded()
        return activeKYCRepo.activeKyc.mapToUserData(imagesUtility: self.imagesUtility)
    }
    
    var login: String {
        loginBehaviorRelay.value
    }
    
    var accountType: AccountType {
        observeAccountTypeManagerIfNeeded()
        return accountTypeManager.accountType
    }
    
    func observeLogin() -> Observable<String> {
        loginBehaviorRelay.asObservable()
    }
    
    func observeUserData() -> Observable<MoreScene.Model.UserType?> {
        observeActiveKYCRepoIfNeeded()
        return userDataBehaviorRelay.asObservable()
    }
    
    func observeAccountType() -> Observable<AccountType> {
        observeAccountTypeManagerIfNeeded()
        return accountTypeBehaviorRelay.asObservable()
    }
}

extension Optional where Wrapped == ActiveKYCRepo.KYC {
    
    func mapToUserData(
        imagesUtility: ImagesUtility
    ) -> MoreScene.Model.UserType? {
        
        switch self {
        
        case .missing,
             .none:
            return nil
            
        case .form(let form):
            if let generalForm = form as? ActiveKYCRepo.GeneralKYCForm {
                return .general(
                    .init(
                        avatarUrl: generalForm.documents.kycAvatar?.imageUrl(imagesUtility: imagesUtility),
                        name: generalForm.firstName,
                        surname: generalForm.lastName
                    )
                )
            } else if let corporateForm = form as? ActiveKYCRepo.CorporateKYCForm {
                return .corporate(
                    .init(
                        avatarUrl: corporateForm.documents.kycAvatar?.imageUrl(imagesUtility: imagesUtility),
                        name: corporateForm.name,
                        company: corporateForm.company
                    )
                )
            }
            
            return nil
        }
    }
}
