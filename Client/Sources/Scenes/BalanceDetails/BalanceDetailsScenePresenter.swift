import Foundation

public protocol BalanceDetailsScenePresentationLogic {
    
    typealias Event = BalanceDetailsScene.Event
    
    func presentSceneDidUpdate(response: Event.SceneDidUpdate.Response)
    func presentSceneDidUpdateSync(response: Event.SceneDidUpdateSync.Response)
}

extension BalanceDetailsScene {
    
    public typealias PresentationLogic = BalanceDetailsScenePresentationLogic
    
    @objc(BalanceDetailsScenePresenter)
    public class Presenter: NSObject {
        
        public typealias Event = BalanceDetailsScene.Event
        public typealias Model = BalanceDetailsScene.Model
        
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

private extension BalanceDetailsScene.Presenter {
    
    func mapSceneModel(_ sceneModel: Model.SceneModel) -> Model.SceneViewModel {
        
        let content: Model.SceneViewModel.Content = .content(
            sections: [
                .init(
                    id: "section",
                    header: nil,
                    cells: [
                        BalanceDetailsScene.TransactionCell.ViewModel(
                            id: "1",
                            icon: .uiImage(Assets.arrow_back_icon.image),
                            type: "Sent",
                            amount: "-0.016 BTC",
                            amountColor: .red,
                            counterparty: "To bob@mail.com",
                            date: "28 Jul"
                        ),
                        BalanceDetailsScene.TransactionCell.ViewModel(
                            id: "2",
                            icon: .uiImage(Assets.arrow_back_icon.image),
                            type: "Sent",
                            amount: "-1 BTC",
                            amountColor: .systemRed,
                            counterparty: "To bg@distributedlab.com",
                            date: "14 Apr"
                        ),
                        BalanceDetailsScene.TransactionCell.ViewModel(
                            id: "3",
                            icon: .uiImage(Assets.arrow_back_icon.image),
                            type: "Received",
                            amount: "10 BTC",
                            amountColor: .systemGreen,
                            counterparty: "From bg@distributedlab.com",
                            date: "14 Apr"
                        ),
                        BalanceDetailsScene.TransactionCell.ViewModel(
                            id: "4",
                            icon: .uiImage(Assets.arrow_back_icon.image),
                            type: "Received",
                            amount: "1.3 BTC",
                            amountColor: .systemGreen,
                            counterparty: "Issuance/deposit",
                            date: "09 Mar"
                        )
                    ]
                )
            ]
        )
        
        return .init(
            isLoading: sceneModel.loadingStatus == .loading,
            content: content
        )
    }
}

// MARK: - PresenterLogic

extension BalanceDetailsScene.Presenter: BalanceDetailsScene.PresentationLogic {
    
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
