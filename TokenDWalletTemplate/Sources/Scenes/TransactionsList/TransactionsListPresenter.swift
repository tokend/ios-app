import Foundation
import UIKit

protocol TransactionsListScenePresentationLogic {
    func presentTransactionsDidUpdate(response: TransactionsListScene.Event.TransactionsDidUpdate.Response)
    func presentActionsDidChange(response: TransactionsListScene.Event.ActionsDidChange.Response)
    func presentLoadingStatusDidChange(response: TransactionsListScene.Event.LoadingStatusDidChange.Response)
    func presentHeaderTitleDidChange(response: TransactionsListScene.Event.HeaderTitleDidChange.Response)
    func presentSendAction(response: TransactionsListScene.Event.SendAction.Response)
}

extension TransactionsListScene {
    typealias PresentationLogic = TransactionsListScenePresentationLogic
    
    struct Presenter {
        
        private let presenterDispatch: PresenterDispatch
        private let amountFormatter: AmountFormatterProtocol
        private let dateFormatter: DateFormatterProtocol
        private let emptyTitle: String
        
        init(
            presenterDispatch: PresenterDispatch,
            amountFormatter: AmountFormatterProtocol,
            dateFormatter: DateFormatterProtocol,
            emptyTitle: String
            ) {
            
            self.presenterDispatch = presenterDispatch
            self.amountFormatter = amountFormatter
            self.dateFormatter = dateFormatter
            self.emptyTitle = emptyTitle
        }
        
        private func transactionsDidUpdate(_ response: Event.TransactionsDidUpdate.Response) {
            let viewModel: Event.TransactionsDidUpdate.ViewModel
            switch response {
                
            case.success(sections: let responseSections):
                let sections = responseSections.map { (section) -> TransactionsListScene.Model.SectionViewModel in
                    let title: String? = {
                        guard let date = section.date else {
                            return nil
                        }
                        return self.dateFormatter.formatDateForTitle(date)
                    }()
                    let rows = section.transactions.map({ (transaction) -> TransactionsListTableViewCell.Model in
                        
                        let attributes = self.getTransactionAttributes(effect: transaction.amountEffect)
                        
                        let amount: String = self.amountFormatter.formatAmount(
                            transaction.amount,
                            isIncome: nil
                        )
                        
                        let counterparty: String? = transaction.counterparty
                        
                        let additionalInfo: String = self.dateFormatter.formatDateForTransaction(transaction.date)
                        
                        return TransactionsListTableViewCell.Model(
                            identifier: transaction.identifier,
                            balanceId: transaction.balanceId,
                            icon: attributes.icon,
                            iconTint: attributes.iconTint,
                            title: attributes.title,
                            amount: amount,
                            amountColor: attributes.amountColor,
                            counterparty: counterparty,
                            additionalInfo: additionalInfo
                        )
                    })
                    
                    return TransactionsListScene.Model.SectionViewModel(
                        title: title,
                        rows: rows
                    )
                }
                
                viewModel = {
                    if sections.isEmpty {
                        return .empty(title: self.emptyTitle)
                    }
                    return .sections(sections)
                }()
                
            case .failed(error: let error):
                viewModel = .empty(title: error.localizedDescription)
            }
            
            self.presenterDispatch.display { (displayLogic) in
                displayLogic.displayTransactionsDidUpdate(viewModel: viewModel)
            }
        }
        
        private func getTransactionAttributes(effect: Model.Transaction.AmountEffect) -> Attributes {
            let title: String
            let icon: UIImage
            let iconTint: UIColor
            let amountColor: UIColor
            
            switch effect {
                
            case .charged:
                title = Localized(.charged)
                icon = Assets.outgoing.image
                iconTint = Theme.Colors.negativeColor
                amountColor = Theme.Colors.negativeAmountColor
                
            case .charged_from_locked:
                title = Localized(.charged_from_lock)
                icon = Assets.outgoing.image
                iconTint = Theme.Colors.negativeColor
                amountColor = Theme.Colors.negativeAmountColor
                
            case .funded:
                title = Localized(.funded)
                icon = Assets.incoming.image
                iconTint = Theme.Colors.positiveColor
                amountColor = Theme.Colors.positiveAmountColor
                
            case .issued:
                title = Localized(.issued)
                icon = Assets.incoming.image
                iconTint = Theme.Colors.positiveColor
                amountColor = Theme.Colors.positiveAmountColor
                
            case .locked:
                title = Localized(.locked)
                icon = Assets.lock.image
                iconTint = Theme.Colors.neutralColor
                amountColor = Theme.Colors.neutralAmountColor
                
            case .matched:
                title = Localized(.matched)
                icon = Assets.match.image
                iconTint = Theme.Colors.neutralColor
                amountColor = Theme.Colors.neutralAmountColor
                
            case .no_effect:
                title = ""
                icon = Assets.match.image
                iconTint = Theme.Colors.neutralColor
                amountColor = Theme.Colors.neutralAmountColor
                
            case .unlocked:
                title = Localized(.unlocked)
                icon = Assets.unlock.image
                iconTint = Theme.Colors.neutralColor
                amountColor = Theme.Colors.positiveAmountColor
                
            case .withdrawn:
                title = Localized(.withdrawn)
                icon = Assets.outgoing.image
                iconTint = Theme.Colors.negativeColor
                amountColor = Theme.Colors.negativeAmountColor
                
            case .pending:
                title = Localized(.pending_order)
                icon = Assets.outgoing.image
                iconTint = Theme.Colors.neutralColor
                amountColor = Theme.Colors.neutralAmountColor
                
            case .sale:
                title = Localized(.investment)
                icon = Assets.outgoing.image
                iconTint = Theme.Colors.negativeColor
                amountColor = Theme.Colors.negativeAmountColor
            }
            
            return Attributes(
                title: title,
                icon: icon,
                iconTint: iconTint,
                amountColor: amountColor
            )
        }
    }
}

extension TransactionsListScene.Presenter: TransactionsListScene.PresentationLogic {
    func presentTransactionsDidUpdate(response: TransactionsListScene.Event.TransactionsDidUpdate.Response) {
        self.transactionsDidUpdate(response)
    }
    
    func presentActionsDidChange(response: TransactionsListScene.Event.ActionsDidChange.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayActionsDidChange(viewModel: viewModel)
        }
    }
    
    func presentLoadingStatusDidChange(response: TransactionsListScene.Event.LoadingStatusDidChange.Response) {
        let viewModel: TransactionsListScene.Event.LoadingStatusDidChange.ViewModel = {
            switch response {
            case .loading:
                return .loading
            case .loaded:
                return .loaded
            }
        }()
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayLoadingStatusDidChange(viewModel: viewModel)
        }
    }
    
    func presentHeaderTitleDidChange(response: TransactionsListScene.Event.HeaderTitleDidChange.Response) {
        let title: String? = {
            guard let date = response.date else {
                return nil
            }
            return self.dateFormatter.formatDateForTitle(date)
        }()
        let animation: TableViewStickyHeader.ChangeTextAnimationType = {
            guard response.animated else {
                return .withoutAnimation
            }
            if response.animateDown {
                return .animateDown
            } else {
                return .animateUp
            }
        }()
        
        let viewModel = TransactionsListScene.Event.HeaderTitleDidChange.ViewModel(
            title: title,
            animation: animation
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayHeaderTitleDidChange(viewModel: viewModel)
        }
    }
    
    func presentSendAction(response: TransactionsListScene.Event.SendAction.Response) {
        let viewModel = TransactionsListScene.Event.SendAction.ViewModel(balanceId: response.balanceId)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySendAction(viewModel: viewModel)
        }
    }
}

extension TransactionsListScene.Presenter {
    struct Attributes {
        let title: String
        let icon: UIImage
        let iconTint: UIColor
        let amountColor: UIColor
    }
}
