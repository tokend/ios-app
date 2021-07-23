import Foundation

public protocol MoreScenePresentationLogic {
    
    typealias Event = MoreScene.Event
    
    func presentSceneDidUpdate(response: Event.SceneDidUpdate.Response)
    func presentSceneDidUpdateSync(response: Event.SceneDidUpdateSync.Response)
}

extension MoreScene {
    
    public typealias PresentationLogic = MoreScenePresentationLogic
    
    @objc(MoreScenePresenter)
    public class Presenter: NSObject {
        
        public typealias Event = MoreScene.Event
        public typealias Model = MoreScene.Model
        
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

private extension MoreScene.Presenter {
    
    func mapSceneModel(_ sceneModel: Model.SceneModel) -> Model.SceneViewModel {
        
        return .init(
            isLoading: sceneModel.loadingStatus == .loading,
            content: .content(
                sections: [
                    .init(
                        id: "user_section",
                        header: nil,
                        cells: [
                            MoreScene.UserCell.ViewModel(
                                id: "user",
                                avatar: nil,
                                abbreviation: "YM",
                                name: "Yegor Miroshnychenko",
                                accountType: "Unverified"
                            )
                        ]
                    ),
                    .init(
                        id: "features_section",
                        header: nil,
                        cells: [
                            MoreScene.IconTitleDisclosureCell.ViewModel(
                                id: "deposit",
                                icon: .uiImage(Assets.arrow_back_icon.image),
                                title: Localized(.more_deposit_title)
                            ),
                            MoreScene.IconTitleDisclosureCell.ViewModel(
                                id: "withdraw",
                                icon: .uiImage(Assets.arrow_back_icon.image),
                                title: Localized(.more_withdraw_title)
                            ),
                            MoreScene.IconTitleDisclosureCell.ViewModel(
                                id: "explore_sales",
                                icon: .uiImage(Assets.arrow_down_icon.image),
                                title: Localized(.more_explore_sales_title)
                            ),
                            MoreScene.IconTitleDisclosureCell.ViewModel(
                                id: "trade",
                                icon: .uiImage(Assets.arrow_up_icon.image),
                                title: Localized(.more_trade_title)
                            ),
                            MoreScene.IconTitleDisclosureCell.ViewModel(
                                id: "polls",
                                icon: .uiImage(Assets.arrow_right_icon.image),
                                title: Localized(.more_polls_title)
                            )
                        ]
                    ),
                    .init(
                        id: "settings",
                        header: nil,
                        cells: [
                            MoreScene.IconTitleDisclosureCell.ViewModel(
                                id: "settings",
                                icon: .uiImage(Assets.more_tab_icon.image),
                                title: Localized(.more_settings_title)
                            )
                        ]
                    )
                ]
            )
        )
    }
}

// MARK: - PresenterLogic

extension MoreScene.Presenter: MoreScene.PresentationLogic {
    
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
