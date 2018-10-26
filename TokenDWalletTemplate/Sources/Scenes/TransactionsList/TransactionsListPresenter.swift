import Foundation
import UIKit

protocol TransactionsListScenePresentationLogic {
    func presentTransactionsDidUpdate(response: TransactionsListScene.Event.TransactionsDidUpdate.Response)
    func presentLoadingStatusDidChange(response: TransactionsListScene.Event.LoadingStatusDidChange.Response)
    func presentHeaderTitleDidChange(response: TransactionsListScene.Event.HeaderTitleDidChange.Response)
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
                        let title: String
                        let icon: UIImage
                        
                        switch transaction.type {
                        case .payment(let sent):
                            title = sent ? "Sent" : "Received"
                            icon = sent ? #imageLiteral(resourceName: "Outcome icon") : #imageLiteral(resourceName: "Income icon")
                            
                        case .createIssuance:
                            title = "Deposit"
                            icon = #imageLiteral(resourceName: "Income icon")
                            
                        case .createWithdrawal:
                            title = "Withdrawal"
                            icon = #imageLiteral(resourceName: "Outcome icon")
                            
                        case .manageOffer(let sold):
                            title = sold ? "Sold" : "Bought"
                            icon = sold ? #imageLiteral(resourceName: "Outcome icon") : #imageLiteral(resourceName: "Income icon")
                            
                        case .checkSaleState(let income):
                            title = "Investment"
                            icon = income ? #imageLiteral(resourceName: "Income icon") : #imageLiteral(resourceName: "Outcome icon")
                            
                        case .pendingOffer(let buy):
                            title = buy ? "Buy" : "Sell"
                            icon = buy ? #imageLiteral(resourceName: "Income icon") : #imageLiteral(resourceName: "Outcome icon")
                        }
                        
                        let amount: String = self.amountFormatter.formatAmount(transaction.amount)
                        let amountColor: UIColor = {
                            switch transaction.amountType {
                            case .positive:
                                return Theme.Colors.positiveAmountColor
                            case .negative:
                                return Theme.Colors.negativeAmountColor
                            case .neutral:
                                return Theme.Colors.neutralAmountColor
                            }
                        }()
                        
                        let counterparty: String? = transaction.counterparty
                        
                        var additionalInfo: String?
                        if let rate = transaction.rate {
                            additionalInfo = self.amountFormatter.formatAmount(rate)
                        } else {
                            additionalInfo = self.dateFormatter.formatDateForTransaction(transaction.date)
                        }
                        
                        return TransactionsListTableViewCell.Model(
                            identifier: transaction.identifier,
                            asset: transaction.amount.asset,
                            icon: icon,
                            title: title,
                            amount: amount,
                            amountColor: amountColor,
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
    }
}

extension TransactionsListScene.Presenter: TransactionsListScene.PresentationLogic {
    func presentTransactionsDidUpdate(response: TransactionsListScene.Event.TransactionsDidUpdate.Response) {
        self.transactionsDidUpdate(response)
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
}
