import Foundation
import RxSwift
import RxCocoa

public protocol LocalSignInUserAvatarUrlProviderProtocol {
    
    var avatarUrl: String? { get }
    func observeAvatarUrl() -> Observable<String?>
}

extension LocalSignInScene {
    public typealias UserAvatarUrlProviderProtocol = LocalSignInUserAvatarUrlProviderProtocol
}
