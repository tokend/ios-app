import Foundation

public protocol SendConfirmationScenePresentationLogic {
    
    typealias Event = SendConfirmationScene.Event
    
    func presentSceneDidUpdate(response: Event.SceneDidUpdate.Response)
    func presentSceneDidUpdateSync(response: Event.SceneDidUpdateSync.Response)
    func presentDidTapConfirmationSync(response: Event.DidTapConfirmationSync.Response)
}

extension SendConfirmationScene {
    
    public typealias PresentationLogic = SendConfirmationScenePresentationLogic
    
    @objc(SendConfirmationScenePresenter)
    public class Presenter: NSObject {
        
        public typealias Event = SendConfirmationScene.Event
        public typealias Model = SendConfirmationScene.Model
        
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

private extension SendConfirmationScene.Presenter {
    
    func mapSceneModel(_ sceneModel: Model.SceneModel) -> Model.SceneViewModel {
        
        guard let payment = sceneModel.payment
        else {
            return .init(content: .empty)
        }
        
        var cells: [CellViewAnyModel] = [
            SendConfirmationScene.InfoCell.ViewModel(
                id: "RecipientCell",
                icon: .uiImage(Assets.settings_account_id_icon.image),
                title: "Recipient",
                description: payment.recipientEmail ?? payment.recipientAccountId
            ),
            SendConfirmationScene.InfoCell.ViewModel(
                id: "AmountCell",
                icon: .uiImage(Assets.settings_account_id_icon.image),
                title: "Amount",
                description: "-\(payment.amount) \(payment.assetCode)"
            ),
            SendConfirmationScene.InfoCell.ViewModel(
                id: "FeeCell",
                icon: .uiImage(Assets.settings_account_id_icon.image),
                title: "Fee",
                description: "\(payment.fee) \(payment.assetCode)"
            ),
            SendConfirmationScene.InfoCell.ViewModel(
                id: "ToReceiveCell",
                icon: .uiImage(Assets.settings_account_id_icon.image),
                title: "To receive",
                description: "\(payment.toRecieve) \(payment.assetCode)"
            )
        ]
        
        if let description = payment.description {
            cells.append(
                SendConfirmationScene.InfoCell.ViewModel(
                    id: "DescriptionCell",
                    icon: .uiImage(Assets.settings_account_id_icon.image),
                    title: "Description",
                    description: description
                )
            )
        }
        
        let section: Model.Section = .init(
            id: "PaymentSection",
            header: CommonHeaderView.ViewModel(
                id: "PaymentSectionHeader",
                title: "Details".uppercased()
            ),
            cells: cells
        )
        
        return .init(content: .content(sections: [section]))
    }
}

// MARK: - PresenterLogic

extension SendConfirmationScene.Presenter: SendConfirmationScene.PresentationLogic {
    
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
    
    public func presentDidTapConfirmationSync(response: Event.DidTapConfirmationSync.Response) {
        let viewModel: Event.DidTapConfirmationSync.ViewModel = response
        self.presenterDispatch.displaySync { (displayLogic) in
            displayLogic.displayDidTapConfirmationSync(viewModel: viewModel)
        }
    }
}
