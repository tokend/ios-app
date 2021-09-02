import Foundation

public protocol SendAmountScenePresentationLogic {
    
    typealias Event = SendAmountScene.Event
    
    func presentSceneDidUpdate(response: Event.SceneDidUpdate.Response)
    func presentSceneDidUpdateSync(response: Event.SceneDidUpdateSync.Response)
}

extension SendAmountScene {
    
    public typealias PresentationLogic = SendAmountScenePresentationLogic
    
    @objc(SendAmountScenePresenter)
    public class Presenter: NSObject {
        
        public typealias Event = SendAmountScene.Event
        public typealias Model = SendAmountScene.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        
        // MARK: -
        
        public init(
            presenterDispatch: PresenterDispatch
        ) {
            
            self.presenterDispatch = presenterDispatch
        }
    }
}

// MARK: - Private methods

private extension SendAmountScene.Presenter {
    
    func mapSceneModel(_ sceneModel: Model.SceneModel) -> Model.SceneViewModel {
        
//        let selectedBalance: Model.Balance? = sceneModel.balancesList.first(where: { $0.id == sceneModel.selectedBalanceId })
        
        return .init(
            recipientAddress: "To \(sceneModel.recipientAddress)",
            amount: sceneModel.amount,
            assetCode: "BTC", //selectedBalance?.assetCode ?? "",
            fee: "No fee",
            description: sceneModel.description
        )
    }
}

// MARK: - PresenterLogic

extension SendAmountScene.Presenter: SendAmountScene.PresentationLogic {
    
    public func presentSceneDidUpdate(response: Event.SceneDidUpdate.Response) {
        let viewModel = mapSceneModel(response.sceneModel)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySceneDidUpdate(
                viewModel: .init(
                    viewModel: viewModel,
                    animated: response.animated
                )
            )
        }
    }
    
    public func presentSceneDidUpdateSync(response: Event.SceneDidUpdateSync.Response) {
        let viewModel = mapSceneModel(response.sceneModel)
        self.presenterDispatch.displaySync { (displayLogic) in
            displayLogic.displaySceneDidUpdateSync(
                viewModel: .init(
                    viewModel: viewModel,
                    animated: response.animated
                )
            )
        }
    }
}
