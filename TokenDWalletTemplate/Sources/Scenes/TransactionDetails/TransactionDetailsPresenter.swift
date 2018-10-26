import Foundation

protocol TransactionDetailsPresentationLogic {
    func presentViewDidLoad(response: TransactionDetails.Event.ViewDidLoad.Response)
    func presentTransactionUpdated(response: TransactionDetails.Event.TransactionUpdated.Response)
    func presentTransactionActionsDidUpdate(response: TransactionDetails.Event.TransactionActionsDidUpdate.Response)
    func presentTransactionAction(response: TransactionDetails.Event.TransactionAction.Response)
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
                        let cellModel = TransactionDetailsCell.Model(
                            title: cellData.title, identifier: cellData.identifier, value: cellData.value
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
}
