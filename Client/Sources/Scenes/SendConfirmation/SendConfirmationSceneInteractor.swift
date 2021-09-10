import Foundation

public protocol SendConfirmationSceneBusinessLogic {
    
    typealias Event = SendConfirmationScene.Event
    
}

extension SendConfirmationScene {
    
    public typealias BusinessLogic = SendConfirmationSceneBusinessLogic
    
    @objc(SendConfirmationSceneInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = SendConfirmationScene.Event
        public typealias Model = SendConfirmationScene.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private var sceneModel: Model.SceneModel
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic
        ) {
            
            self.presenter = presenter
            self.sceneModel = .init()
        }
    }
}

// MARK: - Private methods

private extension SendConfirmationScene.Interactor {
    
    func presentSceneDidUpdate(animated: Bool) {
        let response: Event.SceneDidUpdate.Response = .init(
            sceneModel: sceneModel,
            animated: animated
        )
        presenter.presentSceneDidUpdate(response: response)
    }

    func presentSceneDidUpdateSync(animated: Bool) {
        let response: Event.SceneDidUpdateSync.Response = .init(
            sceneModel: sceneModel,
            animated: animated
        )
        presenter.presentSceneDidUpdateSync(response: response)
    }
}

// MARK: - BusinessLogic

extension SendConfirmationScene.Interactor: SendConfirmationScene.BusinessLogic {
    
}
