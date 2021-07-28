import Foundation
import RxSwift
import RxCocoa

extension LocalSignInScene {
    
    class UserAvatarUrlProvider {
        
        // MARK: - Private properties
        
        private let avatarUrlBehaviorRelay: BehaviorRelay<URL?>
        private let activeKYCStorageManager: ActiveKYCStorageManagerProtocol
        
        private var shouldObserveManager: Bool = true
        private let disposeBag: DisposeBag = .init()
        
        // MARK: -

        init(
            activeKYCStorageManager: ActiveKYCStorageManagerProtocol
        ) {
            self.activeKYCStorageManager = activeKYCStorageManager
            
            avatarUrlBehaviorRelay = .init(value: activeKYCStorageManager.avatarUrl)
        }
    }
}

private extension LocalSignInScene.UserAvatarUrlProvider {
    
    func observeStorageManager() {
        activeKYCStorageManager
            .observeKYCAvatar()
            .subscribe(onNext: { [weak self] (value) in
                self?.avatarUrlBehaviorRelay.accept(value)
            })
            .disposed(by: disposeBag)
    }
}

extension LocalSignInScene.UserAvatarUrlProvider: LocalSignInScene.UserAvatarUrlProviderProtocol {
    var avatarUrl: URL? {
        avatarUrlBehaviorRelay.value
    }
    
    func observeAvatarUrl() -> Observable<URL?> {
        if shouldObserveManager {
            observeStorageManager()
            shouldObserveManager = false
        }
        
        return avatarUrlBehaviorRelay.asObservable()
    }
}
