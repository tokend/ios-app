import UIKit

protocol ConfirmationScenePresentationLogic {
    func presentViewDidLoad(response: ConfirmationScene.Event.ViewDidLoad.Response)
    func presentSectionsUpdated(response: ConfirmationScene.Event.SectionsUpdated.Response)
    func presentConfirmAction(response: ConfirmationScene.Event.ConfirmAction.Response)
}

extension ConfirmationScene {
    typealias PresentationLogic = ConfirmationScenePresentationLogic
    
    struct Presenter {
        
        private let presenterDispatch: PresenterDispatch
        
        init(presenterDispatch: PresenterDispatch) {
            self.presenterDispatch = presenterDispatch
        }
        
        // MARK: -
        
        private func getSectionViewModels(_ sectionModels: [Model.SectionModel]) -> [Model.SectionViewModel] {
            let sectionViewModels = sectionModels.map { (sectionModel) -> Model.SectionViewModel in
                let cells = sectionModel.cells.map { (cellModel) -> CellViewAnyModel in
                    return self.getCellViewModel(cellModel)
                }
                
                let sectionViewModel = Model.SectionViewModel(
                    title: sectionModel.title,
                    cells: cells
                )
                
                return sectionViewModel
            }
            
            return sectionViewModels
        }
        
        private func getCellViewModel(_ cellModel: Model.CellModel) -> CellViewAnyModel {
            switch cellModel.cellType {
                
            case .boolSwitch(let switchedOn):
                return View.TitleBoolSwitchViewModel(
                    hint: cellModel.hint,
                    cellType: cellModel.cellType,
                    identifier: cellModel.identifier,
                    switchedOn: switchedOn
                )
                
            case .text(let title):
                let icon = self.getIconFor(identifier: cellModel.identifier)
                return View.TitleTextViewModel(
                    hint: cellModel.hint,
                    cellType: cellModel.cellType,
                    identifier: cellModel.identifier,
                    isDisabled: cellModel.isDisabled,
                    title: title,
                    icon: icon
                )
            }
        }
        
        private func getIconFor(identifier: CellIdentifier) -> UIImage {
            var image: UIImage?
            switch identifier {
                
            case .amount:
                image = Assets.amount.image
                
            case .recipient:
                image = Assets.recipient.image
                
            case .destination:
                image = Assets.destination.image
                
            case .description:
                image = Assets.reference.image
                
            case .price:
                image = Assets.price.image
                
            case .sale:
                image = Assets.exploreFundsIcon.image
                
            case .toPay,
                 .toPayAmount,
                 .toPayFee,
                 .toReceive,
                 .toReceiveAmount,
                 .toReceiveFee,
                 .fee,
                 .recipientFee,
                 .payRecipientFee,
                 .token,
                 .investment,
                 .fixedFee,
                 .percentFee,
                 .test,
                 .total:
                
                break
            }
            return image ?? UIImage()
        }
    }
}

extension ConfirmationScene.Presenter: ConfirmationScene.PresentationLogic {
    func presentViewDidLoad(response: ConfirmationScene.Event.ViewDidLoad.Response) {
        let viewModel = ConfirmationScene.Event.ViewDidLoad.ViewModel()
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayViewDidLoad(viewModel: viewModel)
        }
    }
    
    func presentSectionsUpdated(response: ConfirmationScene.Event.SectionsUpdated.Response) {
        let viewModel = ConfirmationScene.Event.SectionsUpdated.ViewModel(
            sectionViewModels: self.getSectionViewModels(response.sectionModels)
        )
        self.presenterDispatch.display { displayLogic in
            displayLogic.displaySectionsUpdated(viewModel: viewModel)
        }
    }
    
    func presentConfirmAction(response: ConfirmationScene.Event.ConfirmAction.Response) {
        let viewModel: ConfirmationScene.Event.ConfirmAction.ViewModel
        switch response {
            
        case .loading:
            viewModel = .loading
            
        case .loaded:
            viewModel = .loaded
            
        case .failed(let error):
            viewModel = .failed(errorMessage: error.localizedDescription)
            
        case .succeeded:
            viewModel = .succeeded
        }
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayConfirmAction(viewModel: viewModel)
        }
    }
}
