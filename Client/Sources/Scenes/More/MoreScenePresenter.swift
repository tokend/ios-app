import Foundation

public protocol MoreScenePresentationLogic {
    
    typealias Event = MoreScene.Event
    
    func presentSceneDidUpdate(response: Event.SceneDidUpdate.Response)
    func presentSceneDidUpdateSync(response: Event.SceneDidUpdateSync.Response)
    func presentItemTapSync(response: Event.ItemTapSync.Response)
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
        
        var sections: [Model.Section] = []
        
        let userCellId: String = "user_cell"
        let userSectionId: String = "user_section"
        
        if let user = sceneModel.userData {
            
            let avatar: TokenDUIImage?
            let abbreviation: String
            let name: String
            
            switch user {
            
            case .general(let info):
                if let avatarUrl = info.avatarUrl {
                    avatar = .url(avatarUrl)
                } else {
                    avatar = nil
                }
                
                abbreviation = [info.name.firstCharacterString ?? "", info.surname.firstCharacterString ?? ""].joined().uppercased()
                name = [info.name, info.surname].joined(separator: " ")
                
            case .corporate(let info):
                if let avatarUrl = info.avatarUrl {
                    avatar = .url(avatarUrl)
                } else {
                    avatar = nil
                }
                
                abbreviation = info.name.firstCharacterString ?? ""
                name = info.name
            }
            
            let userCell = MoreScene.UserCell.ViewModel(
                id: userCellId,
                avatar: avatar,
                abbreviation: abbreviation,
                name: name,
                accountType: sceneModel.accountType.localizedTitle
            )
            
            sections.append(
                .init(
                    id: userSectionId,
                    header: nil,
                    cells: [userCell]
                )
            )
        } else {
            let userCell = MoreScene.UserCell.ViewModel(
                id: userCellId,
                avatar: nil,
                abbreviation: (sceneModel.login.firstCharacterString ?? "").uppercased(),
                name: sceneModel.login,
                accountType: sceneModel.accountType.localizedTitle
            )
            
            sections.append(
                .init(
                    id: userSectionId,
                    header: nil,
                    cells: [userCell]
                )
            )
        }
        
        var itemsCells: [CellViewAnyModel] = []
        
        for item in sceneModel.items {
            
            switch item {
            
            case .deposit:
                itemsCells.append(MoreScene.IconTitleDisclosureCell.ViewModel(
                    id: item.rawValue,
                    icon: .uiImage(Assets.more_deposit_icon.image),
                    title: Localized(.more_deposit_title)
                ))
                
            case .withdraw:
                itemsCells.append(MoreScene.IconTitleDisclosureCell.ViewModel(
                    id: "withdraw",
                    icon: .uiImage(Assets.more_withdraw_icon.image),
                    title: Localized(.more_withdraw_title)
                ))
                
            case .exploreSales:
                itemsCells.append(MoreScene.IconTitleDisclosureCell.ViewModel(
                    id: "explore_sales",
                    icon: .uiImage(Assets.more_explore_sales_icon.image),
                    title: Localized(.more_explore_sales_title)
                ))
                
            case .trade:
                itemsCells.append(MoreScene.IconTitleDisclosureCell.ViewModel(
                    id: "trade",
                    icon: .uiImage(Assets.more_trade_icon.image),
                    title: Localized(.more_trade_title)
                ))
                
            case .polls:
                itemsCells.append(MoreScene.IconTitleDisclosureCell.ViewModel(
                    id: "polls",
                    icon: .uiImage(Assets.more_polls_icon.image),
                    title: Localized(.more_polls_title)
                ))
                
            case .settings:
                itemsCells.append(MoreScene.IconTitleDisclosureCell.ViewModel(
                    id: "settings",
                    icon: .uiImage(Assets.more_settings_icon.image),
                    title: Localized(.more_settings_title)
                ))
            }
        }
        
        sections.append(contentsOf: [
            .init(
                id: "features_section",
                header: nil,
                cells: itemsCells
            )
        ])
        
        return .init(
            isLoading: sceneModel.loadingStatus == .loading,
            content: .content(
                sections: sections
            )
        )
    }
}

// MARK: - Mappers

extension AccountType {
    
    var localizedTitle: String {
        
        switch self {
        case .blocked:
            return Localized(.more_user_blocked_status)
        case .corporate:
            return Localized(.more_user_corporate_status)
        case .general:
            return Localized(.more_user_general_status)
        case .unverified:
            return Localized(.more_user_unverified_status)
        }
    }
}

private extension String {
    
    var firstCharacterString: String? {
        if let first = first {
            return String(first)
        } else {
            return nil
        }
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
    
    public func presentItemTapSync(response: Event.ItemTapSync.Response) {
        let viewModel: Event.ItemTapSync.ViewModel = .init(
            item: response.item
        )
        self.presenterDispatch.displaySync { displayLogic in
            displayLogic.displayItemTapSync(viewModel: viewModel)
        }
    }
}
