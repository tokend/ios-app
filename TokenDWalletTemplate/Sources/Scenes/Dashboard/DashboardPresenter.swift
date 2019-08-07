import Foundation

protocol DashboardScenePresentationLogic {
    func presentPlugInsDidChange(response: DashboardScene.Event.PlugInsDidChange.Response)
}

extension DashboardScene {
    typealias PresentationLogic = DashboardScenePresentationLogic
    
    struct Presenter {
        
        private let presenterDispatch: PresenterDispatch
        
        init(presenterDispatch: PresenterDispatch) {
            self.presenterDispatch = presenterDispatch
        }
    }
}

extension DashboardScene.Presenter: DashboardScene.PresentationLogic {
    func presentPlugInsDidChange(response: DashboardScene.Event.PlugInsDidChange.Response) {
        let viewModel = DashboardScene.Event.PlugInsDidChange.ViewModel(
            plugIns: response.plugIns
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayPlugInsDidChange(viewModel: viewModel)
        }
    }
}
