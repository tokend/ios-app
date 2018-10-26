import Foundation

protocol SideMenuPresentationLogic {
    func presentViewDidLoad(response: SideMenu.Event.ViewDidLoad.Response)
}

extension SideMenu {
    typealias PresentationLogic = SideMenuPresentationLogic
    typealias CellModel = SideMenuTableViewCell.Model
    
    struct Presenter {
        
        private let presenterDispatch: PresenterDispatch
        
        init(presenterDispatch: PresenterDispatch) {
            self.presenterDispatch = presenterDispatch
        }
        
        // MARK: - Private
        
        private func getCellModelSections(_ sections: [[Model.MenuItem]]) -> [[CellModel]] {
            let cellSections: [[CellModel]] = sections.map { (section) -> [CellModel] in
                let cellModelSection: [CellModel] = section.map({ (menuItem) -> CellModel in
                    let cellModel = CellModel(
                        icon: menuItem.iconImage,
                        title: menuItem.title,
                        onClick: menuItem.onSelected
                    )
                    
                    return cellModel
                })
                
                return cellModelSection
            }
            
            return cellSections
        }
    }
}

extension SideMenu.Presenter: SideMenu.PresentationLogic {
    func presentViewDidLoad(response: SideMenu.Event.ViewDidLoad.Response) {
        let cellModelSections = self.getCellModelSections(response.sections)
        let viewModel = SideMenu.Event.ViewDidLoad.ViewModel(
            header: response.header,
            sections: cellModelSections
        )
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayViewDidLoad(viewModel: viewModel)
        }
    }
}
