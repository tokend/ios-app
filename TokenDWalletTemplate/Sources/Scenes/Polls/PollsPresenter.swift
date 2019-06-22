import Foundation

public protocol PollsPresentationLogic {
    typealias Event = Polls.Event
    
    func presentSceneUpdated(response: Event.SceneUpdated.Response)
}

extension Polls {
    public typealias PresentationLogic = PollsPresentationLogic
    
    @objc(PollsPresenter)
    public class Presenter: NSObject {
        
        public typealias Event = Polls.Event
        public typealias Model = Polls.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        
        // MARK: -
        
        public init(presenterDispatch: PresenterDispatch) {
            self.presenterDispatch = presenterDispatch
        }
    }
}

extension Polls.Presenter: Polls.PresentationLogic {
    
    public func presentSceneUpdated(response: Event.SceneUpdated.Response) {
        let polls = response.polls.map { (poll) -> Polls.PollCell.ViewModel in
            return Polls.PollCell.ViewModel(topic: poll.topic)
        }
        let asset = Localized(
            .asset_colon,
            replace: [
                .asset_colon_replace_code: response.selectedAsset.code
            ]
        )
        let viewModel = Event.SceneUpdated.ViewModel(
            polls: polls,
            asset: asset
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySceneUpdated(viewModel: viewModel)
        }
    }
}
