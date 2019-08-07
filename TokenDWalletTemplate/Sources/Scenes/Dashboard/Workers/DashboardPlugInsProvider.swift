import Foundation
import RxSwift
import RxCocoa

extension DashboardScene {
    class PlugInsProvider {
        
        private let plugIns: [PlugIn]
        
        init(
            plugIns: [PlugIn]
            ) {
            
            self.plugIns = plugIns
        }
    }
}

extension DashboardScene.PlugInsProvider: DashboardScene.PlugInsProviderProtocol {
    func observePlugIns() -> Observable<[DashboardPlugInsProviderProtocol.PlugIn]> {
        return BehaviorRelay(value: self.plugIns).asObservable()
    }
}
