import Foundation
import RxSwift
import RxCocoa
import TokenDSDK

class ActiveKYCStorageManager {
    
    // MARK: - Private properties
    
    private let avatarUrlBehaviorRelay: BehaviorRelay<URL?> = .init(value: nil)
    private let userDefaults: UserDefaults = UserDefaults.standard
    private let avatarUrlUserDefaultsKey: String = "avatarUrl"
    private let imagesUtility: ImagesUtility
    
    // MARK: -
    
    init(
        imagesUtility: ImagesUtility
    ) {
        self.imagesUtility = imagesUtility
    }
}

private extension ActiveKYCStorageManager {
    
    func getUserDefaultsAvatarUrl() -> URL? {
        if let string = userDefaults.string(forKey: avatarUrlUserDefaultsKey) {
            return URL(string: string)
        } else {
            return nil
        }
    }
    
    func setUserDefaultsAvatarUrl(_ value: String?) {
        userDefaults.set(value, forKey: avatarUrlUserDefaultsKey)
    }
}

extension ActiveKYCStorageManager: ActiveKYCStorageManagerProtocol {
    var avatarUrl: URL? {
        return avatarUrlBehaviorRelay.value
    }
    
    func observeKYCAvatar() -> Observable<URL?> {
        avatarUrlBehaviorRelay.accept(getUserDefaultsAvatarUrl())
        return avatarUrlBehaviorRelay.asObservable()
    }
    
    func updateStorage(with form: AccountKYCForm?) {
//        if let activeKYCForm = form as? ActiveKYCRepo.GeneralKYCForm {
//            let avatarUrl = activeKYCForm.documents.kycAvatar?.imageUrl(imagesUtility: imagesUtility)
//            self.setUserDefaultsAvatarUrl(avatarUrl?.absoluteString)
//            avatarUrlBehaviorRelay.accept(avatarUrl)
//        } else {
//            self.setUserDefaultsAvatarUrl(nil)
//            avatarUrlBehaviorRelay.accept(nil)
//        }
    }
    
    func resetStorage() {
        userDefaults.removeObject(forKey: avatarUrlUserDefaultsKey)
        avatarUrlBehaviorRelay.accept(nil)
    }
}

private extension Document {

    func imageUrl(
        imagesUtility: ImagesUtility
    ) -> URL? {

        switch self {

        case .new:
            return nil

        case .uploaded(let attachment):
            return imagesUtility.getImageURL(attachment)
        }
    }
}
