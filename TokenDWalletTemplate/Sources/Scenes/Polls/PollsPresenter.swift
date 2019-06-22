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
        private let percentFormatter: PercentFormatterProtocol
        
        // MARK: -
        
        public init(
            presenterDispatch: PresenterDispatch,
            percentFormatter: PercentFormatterProtocol
            ) {
            
            self.presenterDispatch = presenterDispatch
            self.percentFormatter = percentFormatter
        }
        
        // MARK: - Private
        
        private func getChoiceViewModel(
            models: [Model.Poll.Choice],
            currentChoice: Int?
            ) -> [Polls.PollsChoiceCell.ViewModel] {
            
            return models.map({ (choice) -> Polls.PollsChoiceCell.ViewModel in
                var isSelected = false
                if let currentChoice = currentChoice {
                    isSelected = currentChoice == choice.value
                }
                var resultViewModel: PollsChoiceCell.ViewModel.Result?
                if let result = choice.result {
                    let relation = result.totalVotes != 0 ?
                        Float(result.voteCounts / result.totalVotes) : 0
                    
                    let percentageText = self.percentFormatter.formatPercantage(
                        percent: relation * 100
                    )
                    resultViewModel = PollsChoiceCell.ViewModel.Result(
                        percentageText: percentageText,
                        percentage: relation
                    )
                }
                return Polls.PollsChoiceCell.ViewModel(
                    name: choice.name,
                    choiceValue: choice.value,
                    isSelected: isSelected,
                    result: resultViewModel
                )
            })
        }
    }
}

extension Polls.Presenter: Polls.PresentationLogic {
    
    public func presentSceneUpdated(response: Event.SceneUpdated.Response) {
        let polls = response.polls.map { (poll) -> Polls.PollCell.ViewModel in
            let choiceViewModels = self.getChoiceViewModel(
                models: poll.choices,
                currentChoice: poll.currentChoice
            )
            let isVotable = poll.choices.allSatisfy({ (choice) -> Bool in
                return choice.result != nil
            })
            let actionTitle: String
            let actionType: Model.ActionType
            if isVotable {
                actionTitle = Localized(.submit_vote)
                actionType = .submit
            } else {
                actionTitle = Localized(.remove_vote)
                actionType = .remove
            }
            return Polls.PollCell.ViewModel(
                pollId: poll.id,
                question: poll.subject,
                choicesViewModels: choiceViewModels,
                isVotable: isVotable,
                actionTitle: actionTitle,
                actionType: actionType
            )
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
