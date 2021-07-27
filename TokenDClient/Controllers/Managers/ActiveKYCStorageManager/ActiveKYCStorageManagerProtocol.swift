import Foundation
import RxSwift
import RxCocoa

public protocol ActiveKYCStorageManagerProtocol {
    
    var avatarUrl: String? { get }
    
    func observeKYCAvatar() -> Observable<String?>
    
    func updateStorage(with form: ActiveKYCRepo.KYCForm?)
    func resetStorage()
}
