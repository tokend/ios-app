import Foundation
import UIKit

protocol SettingsPresentationLogic {
    func presentSectionsUpdated(response: Settings.Event.SectionsUpdated.Response)
    func presentDidSelectCell(response: Settings.Event.DidSelectCell.Response)
    func presentDidSelectSwitch(response: Settings.Event.DidSelectSwitch.Response)
}

extension Settings {
    typealias PresentationLogic = SettingsPresentationLogic
    
    struct Presenter {
        
        private let presenterDispatch: PresenterDispatch
        
        init(presenterDispatch: PresenterDispatch) {
            self.presenterDispatch = presenterDispatch
        }
    }
}

extension Settings.Presenter: Settings.PresentationLogic {
    func presentSectionsUpdated(response: Settings.Event.SectionsUpdated.Response) {
        let sectionModels = self.createSectionModels(sections: response.sectionModels)
        
        let viewModel = Settings.Event.SectionsUpdated.ViewModel(sectionViewModels: sectionModels)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySectionsUpdated(viewModel: viewModel)
        }
    }
    
    func presentDidSelectCell(response: Settings.Event.DidSelectCell.Response) {
        let viewModel = Settings.Event.DidSelectCell.ViewModel(cellIdentifier: response.cellIdentifier)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayDidSelectCell(viewModel: viewModel)
        }
    }
    
    func presentDidSelectSwitch(response: Settings.Event.DidSelectSwitch.Response) {
        var viewModel: Settings.Event.DidSelectSwitch.ViewModel
        
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
}

extension Settings.Presenter {
    func createSectionModels(sections: [Settings.Model.SectionModel]) -> [Settings.Model.SectionViewModel] {
        let sectionModels = sections.map { (section) -> Settings.Model.SectionViewModel in
            var arrayCellModels = [CellViewAnyModel]()
            for cellData in section.cells {
                let cellModel: CellViewAnyModel
                switch cellData.cellType {
                    
                case .disclosureCell:
                    cellModel = SettingsPushCell.Model(
                        title: cellData.title,
                        identifier: cellData.identifier,
                        icon: UIImage(named: cellData.icon) ?? UIImage()
                    )
                    
                case .boolCell(let state):
                    cellModel = SettingsBoolCell.Model(
                        title: cellData.title,
                        identifier: cellData.identifier,
                        icon: UIImage(named: cellData.icon) ?? UIImage(),
                        state: state
                    )
                    
                case .loading:
                    cellModel = SettingsLoadingCell.Model(
                        title: cellData.title,
                        identifier: cellData.identifier,
                        icon: UIImage(named: cellData.icon) ?? UIImage()
                    )
                    
                case .reload:
                    cellModel = SettingsActionCell.Model(
                        title: cellData.title,
                        identifier: cellData.identifier,
                        icon: UIImage(named: cellData.icon) ?? UIImage(),
                        buttonTitle: "Reload"
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
