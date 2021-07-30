import Foundation
import RxSwift

public protocol AccountIDSceneAccountIDProviderProtocol {
    
    var accountId: String { get }
    
    func observeAccountId() -> Observable<String>
}

extension AccountIDScene {
    
    public typealias AccountIDProviderProtocol = AccountIDSceneAccountIDProviderProtocol
}
