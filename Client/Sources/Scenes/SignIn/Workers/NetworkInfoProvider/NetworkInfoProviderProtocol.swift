import Foundation
import RxSwift
import RxCocoa

public protocol SignInSceneNetworkInfoProviderProtocol {
    
    var network: String? { get }
    
    func observeNetwork() -> Observable<String?>
}

extension SignInScene {
    
    public typealias NetworkInfoProviderProtocol = SignInSceneNetworkInfoProviderProtocol
}
