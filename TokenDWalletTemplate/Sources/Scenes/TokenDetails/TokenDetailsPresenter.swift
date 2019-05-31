import Foundation
import UIKit

protocol TokenDetailsPresentationLogic {
    func presentTokenDidUpdate(response: TokenDetailsScene.Event.TokenDidUpdate.Response)
    func presentDidSelectAction(response: TokenDetailsScene.Event.DidSelectAction.Response)
}

extension TokenDetailsScene {
    typealias PresentationLogic = TokenDetailsPresentationLogic
    
    struct Presenter {
        
        private let presenterDispatch: PresenterDispatch
        private let amountFormatter: AmountFormatterProtocol
        private let tokenColoringProvider: TokenColoringProvider
        
        init(
            presenterDispatch: PresenterDispatch,
            amountFormatter: AmountFormatterProtocol,
            tokenColoringProvider: TokenColoringProvider
            ) {
            
            self.presenterDispatch = presenterDispatch
            self.amountFormatter = amountFormatter
            self.tokenColoringProvider = tokenColoringProvider
        }
    }
}

extension TokenDetailsScene.Presenter: TokenDetailsScene.PresentationLogic {
    func presentTokenDidUpdate(response: TokenDetailsScene.Event.TokenDidUpdate.Response) {
        
        guard let token = response.token
            else {
                self.presenterDispatch.display { (displayLogic) in
                    let viewModel = TokenDetailsScene.Event.TokenDidUpdate.ViewModel.empty
                    displayLogic.displayTokenDidUpdate(viewModel: viewModel)
                }
                return
        }
        
        var sections: [TokenDetailsScene.Model.TableSection] = []
        
        let actionButtonTitle: String = {
            switch token.balanceState {
            case .creating,
                 .notCreated:
                return "Create balance"
            case .created:
                return "View history"
            }
        }()
        
        let actionButtonLoading: Bool = {
            if case .creating = token.balanceState {
                return true
            }
            return false
        }()
        
        let codeColor = self.tokenColoringProvider.coloringForCode(token.code)
        
        let mainCardModel = ExploreTokensTableViewCell.Model(
            identifier: token.identifier,
            iconUrl: token.iconUrl,
            codeColor: codeColor,
            title: token.code,
            description: token.name,
            actionButtonTitle: actionButtonTitle,
            actionButtonLoading: actionButtonLoading
        )
        
        let mainCardSection = TokenDetailsScene.Model.TableSection(
            title: nil,
            cells: [mainCardModel],
            description: nil
        )
        sections.append(mainCardSection)
        
        let summaryAvailableModel = TokenDetailsTokenSummaryCell.Model(
            title: "Available",
            value: self.amountFormatter.assetAmountToString(token.availableForIssuance)
        )
        let summaryIssuedModel = TokenDetailsTokenSummaryCell.Model(
            title: "Issued",
            value: self.amountFormatter.assetAmountToString(token.issued)
        )
        let summaryMaximumModel = TokenDetailsTokenSummaryCell.Model(
            title: "Maximum",
            value: self.amountFormatter.assetAmountToString(token.maximumIssuanceAmount)
        )
        let summaryCells: [CellViewAnyModel] = [
            summaryAvailableModel,
            summaryIssuedModel,
            summaryMaximumModel
        ]
        
        let summaryCardCell = TokenDetailsScene.CardView.CardViewModel(
            title: Localized(.asset_summary),
            cells: summaryCells
        )
        let summarySection = TokenDetailsScene.Model.TableSection(
            title: nil,
            cells: [summaryCardCell],
            description: nil
        )
        sections.append(summarySection)
        
        let policyCells = token.policies.map { (policy) -> TokenDetailsTokenSummaryCell.Model in
            return TokenDetailsTokenSummaryCell.Model.init(
                title: policy,
                value: ""
            )
        }
        
        let policyCardCell = TokenDetailsScene.CardView.CardViewModel(
            title: Localized(.policy),
            cells: policyCells
        )
        
        let policiesSection = TokenDetailsScene.Model.TableSection(
            title: nil,
            cells: [policyCardCell],
            description: nil
        )
        sections.append(policiesSection)
        
        if let termsOfUse = token.termsOfUse {
            let termsOfUseModel = TokenDetailsTokenDocumentCell.Model(
                icon: #imageLiteral(resourceName: "Document icon"),
                name: termsOfUse.name,
                link: termsOfUse.link
            )
            
            let termsOfUseCardCell = TokenDetailsScene.CardView.CardViewModel(
                title: Localized(.terms_of_use),
                cells: [termsOfUseModel]
            )
            
            let termsOfUseSection = TokenDetailsScene.Model.TableSection(
                title: nil,
                cells: [termsOfUseCardCell],
                description: nil
            )
            sections.append(termsOfUseSection)
        }
        
        let viewModel = TokenDetailsScene.Event.TokenDidUpdate.ViewModel.sections(sections)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayTokenDidUpdate(viewModel: viewModel)
        }
    }
    
    func presentDidSelectAction(response: TokenDetailsScene.Event.DidSelectAction.Response) {
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayDidSelectAction(viewModel: response)
        }
    }
}
