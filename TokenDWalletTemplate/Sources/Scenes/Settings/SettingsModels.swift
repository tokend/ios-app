import UIKit

enum Settings {
    
    // MARK: - Typealiases
    
    // MARK: -
    
    enum CellIdentifier: String {
        case accountId
        case biometrics
        case changePassword
        case fees
        case licenses
        case limits
        case seed
        case signOut
        case termsOfService
        case tfa
        case verification
    }
    
    enum Model {}
    enum Event {}
}

// MARK: - Models

extension Settings.Model {
    
    struct SceneModel {
        var sections: [SectionModel]
        let termsUrl: URL?
        
        init(termsUrl: URL?) {
            self.sections = []
            self.termsUrl = termsUrl
        }
    }
    
    struct SectionModel {
        let title: String
        let cells: [CellModel]
        let description: String
    }
    
    struct CellModel {
        let title: String
        let icon: UIImage
        let cellType: CellType
        let identifier: Settings.CellIdentifier
    }
    
    struct SectionViewModel {
        let title: String?
        let cells: [CellViewAnyModel]
        let description: String?
    }
}

extension Settings.Model.CellModel {
    
    enum CellType {
        case disclosureCell
        case boolCell(Bool)
        case loading
        case reload
    }
}

// MARK: - Events

extension Settings.Event {
    
    typealias Model = Settings.Model
    
    enum ViewDidLoad {
        struct Request {}
    }
    
    enum SectionsUpdated {
        struct Response {
            var sectionModels: [Settings.Model.SectionModel]
        }
        struct ViewModel {
            var sectionViewModels: [Settings.Model.SectionViewModel]
        }
    }
    
    enum DidSelectCell {
        struct Request {
            let cellIdentifier: Settings.CellIdentifier
        }
        struct Response {
            let cellIdentifier: Settings.CellIdentifier
        }
        struct ViewModel {
            let cellIdentifier: Settings.CellIdentifier
        }
    }
    
    enum DidSelectSwitch {
        struct Request {
            let cellIdentifier: Settings.CellIdentifier
            let state: Bool
        }
        enum Response {
            case loading
            case loaded
            case succeeded
            case failed(Error)
        }
        enum ViewModel {
            case loading
            case loaded
            case succeeded
            case failed(errorMessage: String)
        }
    }
    
    enum DidSelectAction {
        struct Request {
            let cellIdentifier: Settings.CellIdentifier
        }
    }
    
    enum ShowTerms {
        struct Response {
            let url: URL
            
            public init(url: URL) {
                self.url = url
            }
        }
        
        typealias ViewModel = Response
    }
}
