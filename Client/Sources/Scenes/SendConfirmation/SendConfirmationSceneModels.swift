import UIKit
import DifferenceKit

public enum SendConfirmationScene {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension SendConfirmationScene.Model {
    
    struct SceneModel {
        var payment: Payment?
    }
    
    struct SceneViewModel {
        let content: Content
        
        enum Content {
            case content(sections: [Section])
            case empty
        }
    }
    
    struct Section: SectionViewModel {
        
        let id: String
        let header: HeaderFooterViewAnyModel?
        var cells: [CellViewAnyModel]
    }
    

    public struct Payment {
        let recipientAccountId: String
        let recipientEmail: String?
        let amount: Decimal
        let assetCode: String
        let fee: Decimal
        let description: String?
        let toRecieve: Decimal
    }
}

// MARK: - Events

extension SendConfirmationScene.Event {
    
    public typealias Model = SendConfirmationScene.Model
    
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
    
    public enum DidTapConfirmationSync {
        public struct Request {}
        public struct Response {}
        public typealias ViewModel = Response
    }
}

extension SendConfirmationScene.Model.Section: DifferentiableSection {
    
    var differenceIdentifier: String {
        id
    }
    
    func isContentEqual(to source: SendConfirmationScene.Model.Section) -> Bool {
        header.equalsTo(another: source.header)
    }
    
    init(
        source: SendConfirmationScene.Model.Section,
        elements: [CellViewAnyModel]
    ) {
        
        self.id = source.id
        self.header = source.header
        self.cells = elements
    }
}
