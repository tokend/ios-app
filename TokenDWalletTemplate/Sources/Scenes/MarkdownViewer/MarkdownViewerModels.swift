import UIKit

enum MarkdownViewer {
    
    // MARK: - Typealiases
    
    typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    enum Model {}
    enum Event {}
}

// MARK: - Models

extension MarkdownViewer.Model {
    
}

// MARK: - Events

extension MarkdownViewer.Event {
    
    typealias Model = MarkdownViewer.Model
    
    // MARK: -
    
    enum ViewDidLoad {
        struct Request {}
        
        struct Response {
            let markdownString: String
        }
        
        typealias ViewModel = Response
    }
}
