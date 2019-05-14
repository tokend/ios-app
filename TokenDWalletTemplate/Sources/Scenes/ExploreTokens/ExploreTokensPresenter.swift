import Foundation
import UIKit

protocol ExploreTokensPresentationLogic {
    func presentTokensDidChange(response: ExploreTokensScene.Event.TokensDidChange.Response)
    func presentLoadingStatusDidChange(response: ExploreTokensScene.Event.LoadingStatusDidChange.Response)
    func presentDidSelectAction(response: ExploreTokensScene.Event.DidSelectAction.Response)
    func presentError(response: ExploreTokensScene.Event.Error.Response)
}

extension ExploreTokensScene {
    typealias PresentationLogic = ExploreTokensPresentationLogic
    
    struct Presenter {
        
        private let presenterDispatch: PresenterDispatch
        private let tokenColoringProvider: TokenColoringProvider
        
        init(
            presenterDispatch: PresenterDispatch,
            tokenColoringProvider: TokenColoringProvider
            ) {
            
            self.presenterDispatch = presenterDispatch
            self.tokenColoringProvider = tokenColoringProvider
        }
    }
}

extension ExploreTokensScene.Presenter: ExploreTokensScene.PresentationLogic {
    func presentTokensDidChange(response: ExploreTokensScene.Event.TokensDidChange.Response) {
        
        let sections = response.tokens.map { (token) -> ExploreTokensScene.Model.TableSection in
            let actionButtonLoading: Bool
            let actionButtonTitle: String
            
            switch token.balanceState {
                
            case .creating:
                actionButtonLoading = true
                actionButtonTitle = ""
                
            case .notCreated:
                actionButtonLoading = false
                actionButtonTitle = Localized(.create_balance)
                
            case .created:
                actionButtonLoading = false
                actionButtonTitle = Localized(.view_history)
            }
            
            let codeColor = self.tokenColoringProvider.coloringForCode(token.code)
            
            let cellModel = ExploreTokensTableViewCell.Model(
                identifier: token.identifier,
                iconUrl: token.iconUrl,
                codeColor: codeColor,
                title: token.code,
                description: token.name,
                actionButtonTitle: actionButtonTitle,
                actionButtonLoading: actionButtonLoading
            )
            return ExploreTokensScene.Model.TableSection(cells: [cellModel])
        }
        
        let viewModel: ExploreTokensScene.Event.TokensDidChange.ViewModel = {
            if sections.isEmpty {
                return .empty(title: Localized(.no_assets))
            }
            return .sections(sections)
        }()
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayTokensDidChange(viewModel: viewModel)
        }
    }
    
    func presentLoadingStatusDidChange(response: ExploreTokensScene.Event.LoadingStatusDidChange.Response) {
        
        let viewModel: ExploreTokensScene.Event.LoadingStatusDidChange.ViewModel = {
            switch response {
            case .loaded:
                return .loaded
            case .loading:
                return .loading
            }
        }()
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayLoadingStatusDidChange(viewModel: viewModel)
        }
    }
    
    func presentDidSelectAction(response: ExploreTokensScene.Event.DidSelectAction.Response) {
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayDidSelectAction(viewModel: response)
        }
    }
    
    func presentError(response: ExploreTokensScene.Event.Error.Response) {
        self.presenterDispatch.display { (displayLogic) in
            let viewModel = ExploreTokensScene.Event.Error.ViewModel(message: response.error.localizedDescription)
            displayLogic.displayError(viewModel: viewModel)
        }
    }
}
