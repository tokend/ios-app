import Foundation
import RxSwift
import RxCocoa

public enum TFAStatus {
    case undetermined
    case loading
    case failed(Swift.Error)
    case loaded(enabled: Bool)
}

public protocol TFAManagerProtocol {
    
    var status: TFAStatus { get }
    
    func observeTfaStatus(
    ) -> Observable<TFAStatus>
    
    func enableTFA(
        completion: @escaping (Swift.Result<Void, Swift.Error>) -> Void
    )
    
    func disableTFA(
        completion: @escaping (Swift.Result<Void, Swift.Error>) -> Void
    )
}
