import Foundation
import RxSwift
import RxCocoa
import TokenDSDK

class ActiveKYCStorageManager {
    
    // MARK: - Private properties
    
    private let avatarUrlBehaviorRelay: BehaviorRelay<String?> = .init(value: nil)
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
    
    func getUserDefaultsAvatarUrl() -> String? {
        return userDefaults.string(forKey: avatarUrlUserDefaultsKey)
    }
    
    func setUserDefaultsAvatarUrl(_ value: String?) {
        userDefaults.set(value, forKey: avatarUrlUserDefaultsKey)
    }
}

extension ActiveKYCStorageManager: ActiveKYCStorageManagerProtocol {
    var avatarUrl: String? {
        return avatarUrlBehaviorRelay.value
    }
    
    func observeKYCAvatar() -> Observable<String?> {
        avatarUrlBehaviorRelay.accept(getUserDefaultsAvatarUrl())
        return avatarUrlBehaviorRelay.asObservable()
    }
    
    func updateStorage(with form: ActiveKYCRepo.KYCForm?) {
        let avatarUrl = form?.documents.kycAvatar?.imageUrl(imagesUtility: imagesUtility)
        self.setUserDefaultsAvatarUrl(avatarUrl?.absoluteString)
        avatarUrlBehaviorRelay.accept(avatarUrl?.absoluteString)
    }
    
    func resetStorage() {
        userDefaults.removeObject(forKey: avatarUrlUserDefaultsKey)
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
            return attachment.url(imagesUtility: imagesUtility)
        }
    }
}

private extension BlobResponse.BlobContent.Attachment {

    func url(
        imagesUtility: ImagesUtility
    ) -> URL? {

        return imagesUtility.getImageURL(.key(self.key))
    }
}
