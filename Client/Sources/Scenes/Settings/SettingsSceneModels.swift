import UIKit
import DifferenceKit

public enum SettingsScene {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension SettingsScene.Model {
    
    struct Section: SectionViewModel {
        
        let id: String
        let header: HeaderFooterViewAnyModel?
        let cells: [CellViewAnyModel]
    }
    
    struct SceneModel {
        
        var loadingStatus: LoadingStatus
        var sections: [SectionModel]
//        var preferredLanguage:
        var lockAppIsEnabled: Bool
        var biometricsType: BiometricsType
        var biometricsIsEnabled: Bool
        var tfaIsInabled: Bool
    }
    
    struct SceneViewModel {
        
        let isLoading: Bool
        let content: Content
        
        enum Content {
            case content(sections: [Section])
            case empty
        }
    }
    
    public struct SectionModel {
        let id: String
        var items: [Item]
    }
    
    public enum LoadingStatus {
        case loading
        case loaded
    }
    
    public enum Item: String {
        
        case language
        case accountId
        case verification
        case secretSeed
        case signOut
        case lockApp
        case biometrics
        case tfa
        case changePassword
    }
}

// MARK: - Events

extension SettingsScene.Event {
    
    public typealias Model = SettingsScene.Model
    
    // MARK: -
    
    public enum ViewDidLoad {
        public struct Request {}
    }

    public enum ViewDidLoadSync {
        public struct Request {}
    }
    
    public enum SceneDidUpdate {
        public struct Response {
            let sceneModel: Model.SceneModel
            let animated: Bool
        }

        public struct ViewModel {
            let viewModel: Model.SceneViewModel
            let animated: Bool
        }
    }

    public enum SceneDidUpdateSync {
        public struct Response {
            let sceneModel: Model.SceneModel
            let animated: Bool
        }

        public struct ViewModel {
            let viewModel: Model.SceneViewModel
            let animated: Bool
        }
    }
    
    public enum DidTapItemSync {
        public struct Request {
            let id: String
        }
        
        public struct Response {
            let item: Model.Item
        }
        
        public typealias ViewModel = Response
    }
    
    public enum DidRefresh {
        public struct Request { }
    }
}

extension SettingsScene.Model.Section: DifferentiableSection {
    
    var differenceIdentifier: String {
        id
    }
    
    func isContentEqual(to source: SettingsScene.Model.Section) -> Bool {
        header.equalsTo(another: source.header)
    }
    
    init(source: SettingsScene.Model.Section,
         elements: [CellViewAnyModel]) {
        
        self.id = source.id
        self.header = source.header
        self.cells = elements
    }
}
