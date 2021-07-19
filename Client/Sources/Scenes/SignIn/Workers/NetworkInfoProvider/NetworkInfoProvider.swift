import Foundation
import RxSwift
import RxCocoa

extension SignInScene {
    class NetworkInfoProvider {
        
        private let networkInfoBehaviorRelay: BehaviorRelay<String?> = .init(value: nil)
        
        func setNewNetworkInfo(value: String) {
            
            let networkInfo: String = value
                .replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
            networkInfoBehaviorRelay.accept(networkInfo)
        }
    }
}

extension SignInScene.NetworkInfoProvider: SignInScene.NetworkInfoProviderProtocol {
    var network: String? {
        networkInfoBehaviorRelay.value
    }
    
    func observeNetwork() -> Observable<String?> {
        networkInfoBehaviorRelay.asObservable()
    }
}
