import Foundation
import RxSwift
import RxCocoa

public protocol LocalSignInUserAvatarUrlProviderProtocol {
    
    var avatarUrl: URL? { get }
    func observeAvatarUrl() -> Observable<URL?>
}

extension LocalSignInScene {
    public typealias UserAvatarUrlProviderProtocol = LocalSignInUserAvatarUrlProviderProtocol
}
