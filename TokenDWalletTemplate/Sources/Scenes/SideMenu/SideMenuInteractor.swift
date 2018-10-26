import Foundation

protocol SideMenuBusinessLogic {
    func onViewDidLoad(request: SideMenu.Event.ViewDidLoad.Request)
}

extension SideMenu {
    typealias BusinessLogic = SideMenuBusinessLogic
    
    class Interactor {
        
        private let presenter: PresentationLogic
        
        private let headerModel: Model.HeaderModel
        private let sceneModel: Model.SceneModel
        
        init(
            presenter: PresentationLogic,
            headerModel: Model.HeaderModel,
            sceneModel: Model.SceneModel
            ) {
            self.presenter = presenter
            self.headerModel = headerModel
            self.sceneModel = sceneModel
        }
    }
}

extension SideMenu.Interactor: SideMenu.BusinessLogic {
    func onViewDidLoad(request: SideMenu.Event.ViewDidLoad.Request) {
        let response = SideMenu.Event.ViewDidLoad.Response(
            header: self.headerModel,
            sections: self.sceneModel.sections
        )
        self.presenter.presentViewDidLoad(response: response)
    }
}
