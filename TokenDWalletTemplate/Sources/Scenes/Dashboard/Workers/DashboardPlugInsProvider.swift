import Foundation
import RxSwift
import RxCocoa

extension DashboardScene {
    class PlugInsProvider {
        
        private let plugIns: BehaviorRelay<[PlugIn]>
        
        init(
            plugIns: [PlugIn]
            ) {
            
            self.plugIns = BehaviorRelay(value: plugIns)
        }
    }
}

extension DashboardScene.PlugInsProvider: DashboardScene.PlugInsProviderProtocol {
    func observePlugIns() -> Observable<[DashboardPlugInsProviderProtocol.PlugIn]> {
        return self.plugIns.asObservable()
    }
}
