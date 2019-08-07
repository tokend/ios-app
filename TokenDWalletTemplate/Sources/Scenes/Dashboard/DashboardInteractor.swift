import Foundation
import RxSwift
import RxCocoa

protocol DashboardSceneBusinessLogic {
    func onViewDidLoadSync(request: DashboardScene.Event.ViewDidLoadSync.Request)
    func onDidInitiateRefresh(request: DashboardScene.Event.DidInitiateRefresh.Request)
}

extension DashboardScene {
    typealias BusinessLogic = DashboardSceneBusinessLogic
    
    class Interactor {
        
        private var sceneModel: Model.SceneModel = Model.SceneModel(plugIns: [])
        private let presenter: PresentationLogic
        private let queue: DispatchQueue
        private let plugInsProvider: PlugInsProviderProtocol
        private let disposeBag: DisposeBag = DisposeBag()
        
        init(
            presenter: PresentationLogic,
            queue: DispatchQueue,
            plugInsProvider: PlugInsProviderProtocol
            ) {
            
            self.presenter = presenter
            self.queue = queue
            self.plugInsProvider = plugInsProvider
        }
        
        private func observePlugIns() {
            self.plugInsProvider
                .observePlugIns()
                .observeOn(ConcurrentDispatchQueueScheduler(queue: self.queue))
                .subscribe(onNext: { [weak self] (plugIns) in
                    self?.sceneModel.plugIns = plugIns
                    self?.plugInsDidChange()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func plugInsDidChange() {
            let response = Event.PlugInsDidChange.Response(plugIns: self.sceneModel.plugIns)
            self.presenter.presentPlugInsDidChange(response: response)
        }
    }
}

extension DashboardScene.Interactor: DashboardScene.BusinessLogic {
    func onViewDidLoadSync(request: DashboardScene.Event.ViewDidLoadSync.Request) {
        self.observePlugIns()
    }
    
    func onDidInitiateRefresh(request: DashboardScene.Event.DidInitiateRefresh.Request) {
        for plugIn in self.sceneModel.plugIns {
            plugIn.reloadData()
        }
    }
}
