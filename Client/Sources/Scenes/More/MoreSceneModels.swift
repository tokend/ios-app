import UIKit
import DifferenceKit

public enum MoreScene {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension MoreScene.Model {
    
    struct Section: SectionViewModel {
        
        let id: String
        let header: HeaderFooterViewAnyModel?
        let cells: [CellViewAnyModel]
    }
    
    struct SceneModel {
        
        var loadingStatus: LoadingStatus
    }
    
    struct SceneViewModel {
        
        let isLoading: Bool
        let content: Content
        
        enum Content {
            case content(sections: [Section])
            case empty
        }
    }
    
    public enum LoadingStatus {
        case loading
        case loaded
    }
}

// MARK: - Events

extension MoreScene.Event {
    
    public typealias Model = MoreScene.Model
    
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
    
    public enum DidRefresh {
        public struct Request { }
    }
}

extension MoreScene.Model.Section: DifferentiableSection {
    
    var differenceIdentifier: String {
        id
    }
    
    func isContentEqual(to source: MoreScene.Model.Section) -> Bool {
        header.equalsTo(another: source.header)
    }
    
    init(source: MoreScene.Model.Section,
         elements: [CellViewAnyModel]) {
        
        self.id = source.id
        self.header = source.header
        self.cells = elements
    }
}
