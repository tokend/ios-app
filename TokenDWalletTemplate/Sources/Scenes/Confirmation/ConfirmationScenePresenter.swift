import Foundation

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
                let cells = sectionModel.cells.map { (cellModel) -> Model.CellViewModel in
                    return self.getCellViewModel(cellModel)
                }
                
                let sectionViewModel = Model.SectionViewModel(cells: cells)
                
                return sectionViewModel
            }
            
            return sectionViewModels
        }
        
        private func getCellViewModel(_ cellModel: Model.CellModel) -> Model.CellViewModel {
            switch cellModel.cellType {
                
            case .boolSwitch(let value):
                return View.TitleBoolSwitchViewModel(
                    title: cellModel.title,
                    cellType: cellModel.cellType,
                    identifier: cellModel.identifier,
                    value: value
                )
                
            case .text(let value):
                return View.TitleTextViewModel(
                    title: cellModel.title,
                    cellType: cellModel.cellType,
                    identifier: cellModel.identifier,
                    value: value
                )
                
            case .textField(let value, let placeholder, let maxCharacters):
                return View.TitleTextEditViewModel(
                    title: cellModel.title,
                    cellType: cellModel.cellType,
                    identifier: cellModel.identifier,
                    value: value,
                    placeholder: placeholder,
                    maxCharacters: maxCharacters
                )
            }
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
