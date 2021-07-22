import Foundation
import RxSwift
import RxCocoa

public protocol NetworkInfoProviderProtocol {
    
    var network: String? { get }
    
    func observeNetwork() -> Observable<String?>
}
