import Foundation
import RxSwift
import RxCocoa

public protocol SendAmountSceneBusinessLogic {
    
    typealias Event = SendAmountScene.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request)
}

extension SendAmountScene {
    
    public typealias BusinessLogic = SendAmountSceneBusinessLogic
    
    @objc(SendAmountSceneInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = SendAmountScene.Event
        public typealias Model = SendAmountScene.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private var sceneModel: Model.SceneModel
        
        private let disposeBag: DisposeBag = .init()
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            recipientAddress: String,
            selectedBalanceId: String
        ) {
            
            self.presenter = presenter
            self.sceneModel = .init(
                recipientAddress: recipientAddress,
                selectedBalanceId: selectedBalanceId,
                balancesList: []
            )
        }
    }
}

// MARK: - Private methods

private extension SendAmountScene.Interactor {
    
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

extension SendAmountScene.Interactor: SendAmountScene.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {}
    
    public func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request) {
        presentSceneDidUpdateSync(animated: false)
    }
}
