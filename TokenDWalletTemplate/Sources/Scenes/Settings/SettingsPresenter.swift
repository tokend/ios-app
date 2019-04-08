import Foundation
import UIKit

protocol SettingsPresentationLogic {
    
    typealias Event = Settings.Event
    
    func presentSectionsUpdated(response: Event.SectionsUpdated.Response)
    func presentDidSelectCell(response: Event.DidSelectCell.Response)
    func presentDidSelectSwitch(response: Event.DidSelectSwitch.Response)
    func presentShowFees(response: Event.ShowFees.Response)
    func presentShowTerms(response: Event.ShowTerms.Response)
    func presentSignOut(response: Event.SignOut.Response)
}

extension Settings {
    typealias PresentationLogic = SettingsPresentationLogic
    
    struct Presenter {
        
        private let presenterDispatch: PresenterDispatch
        
        init(presenterDispatch: PresenterDispatch) {
            self.presenterDispatch = presenterDispatch
        }
        
        // MARK: - Private
        
        private func createSectionModels(sections: [Settings.Model.SectionModel]) -> [Settings.Model.SectionViewModel] {
            let sectionModels = sections.map { (section) -> Settings.Model.SectionViewModel in
                var arrayCellModels = [CellViewAnyModel]()
                for cellData in section.cells {
                    let cellModel: CellViewAnyModel
                    switch cellData.cellType {
                        
                    case .disclosureCell:
                        cellModel = SettingsPushCell.Model(
                            title: cellData.title,
                            identifier: cellData.identifier,
                            icon: cellData.icon
                        )
                        
                    case .boolCell(let state):
                        cellModel = SettingsBoolCell.Model(
                            title: cellData.title,
                            identifier: cellData.identifier,
                            icon: cellData.icon,
                            state: state
                        )
                        
                    case .loading:
                        cellModel = SettingsLoadingCell.Model(
                            title: cellData.title,
                            identifier: cellData.identifier,
                            icon: cellData.icon
                        )
                        
                    case .reload:
                        cellModel = SettingsActionCell.Model(
                            title: cellData.title,
                            identifier: cellData.identifier,
                            icon: cellData.icon,
                            buttonTitle: Localized(.reload)
                        )
                    }
                    
                    arrayCellModels.append(cellModel)
                }
                let modelSection = Settings.Model.SectionViewModel(
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

extension Settings.Presenter: Settings.PresentationLogic {
    
    typealias Event = Settings.Event
    
    func presentSectionsUpdated(response: Event.SectionsUpdated.Response) {
        let sectionModels = self.createSectionModels(sections: response.sectionModels)
        
        let viewModel = Event.SectionsUpdated.ViewModel(sectionViewModels: sectionModels)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySectionsUpdated(viewModel: viewModel)
        }
    }
    
    func presentDidSelectCell(response: Event.DidSelectCell.Response) {
        let viewModel = Event.DidSelectCell.ViewModel(cellIdentifier: response.cellIdentifier)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayDidSelectCell(viewModel: viewModel)
        }
    }
    
    func presentDidSelectSwitch(response: Event.DidSelectSwitch.Response) {
        var viewModel: Event.DidSelectSwitch.ViewModel
        
        switch response {
            
        case .loading:
            viewModel = .loading
            
        case .loaded:
            viewModel = .loaded
            
        case .succeeded:
            viewModel = .succeeded
            
        case .failed (let error):
            viewModel = .failed(errorMessage: error.localizedDescription)
        }
        
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayDidSelectSwitch(viewModel: viewModel)
        }
    }
    
    func presentShowFees(response: Event.ShowFees.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayShowFees(viewModel: viewModel)
        }
    }
    
    func presentShowTerms(response: Event.ShowTerms.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayShowTerms(viewModel: viewModel)
        }
    }
    
    func presentSignOut(response: Event.SignOut.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySignOut(viewModel: viewModel)
        }
    }
}
