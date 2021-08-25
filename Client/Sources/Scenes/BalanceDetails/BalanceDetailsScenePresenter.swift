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
        
        let cells = sceneModel.transactions.map {
            $0.mapToViewModel()
        }
        
        let content: Model.SceneViewModel.Content = .content(
            sections: [
                .init(
                    id: "section",
                    header: nil,
                    cells: cells
                )
            ]
        )
        
        return .init(
            isLoading: sceneModel.loadingStatus == .loading,
            content: content
        )
    }
}

// MARK: - Mappers

extension BalanceDetailsScene.Model.Transaction {
    
    func mapToViewModel(
    ) -> BalanceDetailsScene.TransactionCell.ViewModel {
        
        let counterparty: String?
        
        switch action {
        
        case .locked,
             .unlocked:
            counterparty = nil
            
        case .charged,
             .chargedFromLocked,
             .funded,
             .issued,
             .matched,
             .withdrawn:
        
            switch transactionType {
            
            case .payment(let accountId, let name):
                counterparty = name ?? accountId.formattedAccountId()
            case .withdrawalRequest(let accountId):
                counterparty = accountId.formattedAccountId()
                
            case .amlAlert,
                 .assetPairUpdate,
                 .atomicSwapAskCreation,
                 .atomicSwapBidCreation,
                 .investment,
                 .issuance,
                 .matchedOffer,
                 .offer,
                 .offerCancellation,
                 .saleCancellation:
                counterparty = nil
            }
        }
        
        return .init(
            id: id,
            icon: .uiImage(Assets.buy_toolbar_icon.image),
            type: "Received",
            amount: "\(amount) \(asset)",
            amountColor: .systemGreen,
            counterparty: counterparty,
            date: "Date"
        )
    }
}

private extension String {
    
    func formattedAccountId() -> String {
        [self[0..<4], "...", self[count - 4..<count]].joined()
    }
}

extension String {
    
    subscript(_ range: Range<Int>) -> String {
        
        let start: Index = index(startIndex, offsetBy: range.startIndex)
        let end: Index = index(start, offsetBy: range.count)
        
        return String(self[start...end])
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
