import Foundation
import RxSwift
import RxCocoa

public protocol ActiveKYCStorageManagerProtocol {
    
    var avatarUrl: URL? { get }
    
    func observeKYCAvatar() -> Observable<URL?>
    
    func updateStorage(with form: AccountKYCForm?)
    func resetStorage()
}
