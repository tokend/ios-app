import UIKit

protocol TransactionDetailsPresentationLogic {
    func presentViewDidLoad(response: TransactionDetails.Event.ViewDidLoad.Response)
    func presentTransactionUpdated(response: TransactionDetails.Event.TransactionUpdated.Response)
    func presentTransactionActionsDidUpdate(response: TransactionDetails.Event.TransactionActionsDidUpdate.Response)
    func presentTransactionAction(response: TransactionDetails.Event.TransactionAction.Response)
    func presentSelectedCell(response: TransactionDetails.Event.SelectedCell.Response)
}

extension TransactionDetails {
    typealias PresentationLogic = TransactionDetailsPresentationLogic
    
    struct Presenter {
        
        private let presenterDispatch: PresenterDispatch
        
        init(presenterDispatch: PresenterDispatch) {
            self.presenterDispatch = presenterDispatch
        }
        
        // MARK: - Private
        
        func createSectionModels(sections: [TransactionDetails.Model.SectionModel])
            -> [TransactionDetails.Model.SectionViewModel] {
                
                let sectionModels = sections.map { (section) -> TransactionDetails.Model.SectionViewModel in
                    var arrayCellModels = [CellViewAnyModel]()
                    
                    for cellData in section.cells {
                        let icon: UIImage
                        var isTruncatable: Bool = false
                        
                        switch cellData.identifier {
                        case .amount:
                            icon = Assets.amount.image
                        case .charged:
                            icon = Assets.outgoing.image
                        case .check:
                            icon = Assets.check.image
                        case .code:
                            icon = Assets.code.image
                        case .date:
                            icon = Assets.date.image
                        case .destination:
                            icon = Assets.destination.image
                        case .email:
                            icon = Assets.email.image
                        case .locked:
                            icon = Assets.lock.image
                        case .matched:
                            icon = Assets.match.image
                        case .price:
                            icon = Assets.price.image
                        case .received:
                            icon = Assets.incoming.image
                        case .recipient:
                            icon = Assets.recipient.image
                            isTruncatable = true
                        case .reference:
                            icon = Assets.reference.image
                        case .sender:
                            icon = Assets.recipient.image
                            isTruncatable = true
                        case .token:
                            icon = Assets.token.image
                        case .unlocked:
                            icon = Assets.unlock.image
                        default:
                            icon = UIImage()
                        }
                        
                        let cellModel = TransactionDetailsCell.Model(
                            identifier: cellData.identifier,
                            icon: icon,
                            title: cellData.title,
                            hint: cellData.hint,
                            isSeparatorHidden: cellData.isSeparatorHidden,
                            isTruncatable: isTruncatable
                        )
                        arrayCellModels.append(cellModel)
                    }
                    
                    let modelSection = TransactionDetails.Model.SectionViewModel(
                        title: section.title,
                        cells: arrayCellModels,
                        description: section.description
                    )
                    return modelSection
                }
                return sectionModels
        }
    }
}

extension TransactionDetails.Presenter: TransactionDetails.PresentationLogic {
    func presentViewDidLoad(response: TransactionDetails.Event.ViewDidLoad.Response) {
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayViewDidLoad(viewModel: TransactionDetails.Event.ViewDidLoad.ViewModel())
        }
    }
    
    func presentTransactionUpdated(response: TransactionDetails.Event.TransactionUpdated.Response) {
        var viewModel: TransactionDetails.Event.TransactionUpdated.ViewModel
        switch response {
            
        case .loading:
            viewModel = .loading
            
        case .loaded:
            viewModel = .loaded
            
        case .succeeded(let sectionModels):
            viewModel = .succeeded(self.createSectionModels(sections: sectionModels))
        }
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayTransactionUpdated(viewModel: viewModel)
        }
    }
    
    func presentTransactionActionsDidUpdate(response: TransactionDetails.Event.TransactionActionsDidUpdate.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayTransactionActionsDidUpdate(viewModel: viewModel)
        }
    }
    
    func presentTransactionAction(response: TransactionDetails.Event.TransactionAction.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayTransactionAction(viewModel: viewModel)
        }
    }
    
    func presentSelectedCell(response: TransactionDetails.Event.SelectedCell.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySelectedCell(viewModel: viewModel)
        }
    }
}
