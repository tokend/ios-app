import Foundation

protocol MarkdownViewerBusinessLogic {
    
    typealias Event = MarkdownViewer.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
}

extension MarkdownViewer {
    typealias BusinessLogic = MarkdownViewerBusinessLogic
    
    class Interactor {
        
        typealias Event = MarkdownViewer.Event
        typealias Model = MarkdownViewer.Model
        
        // MARK: - Public properties
        
        let filePath: String
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        
        // MARK: -
        
        init(
            presenter: PresentationLogic,
            filePath: String
            ) {
            
            self.presenter = presenter
            self.filePath = filePath
        }
        
        // MARK: - Private
        
        private func getMarkdownString() -> String {
            let markdownString: String
            do {
                markdownString = try String(contentsOfFile: self.filePath)
            } catch let error {
                markdownString = error.localizedDescription
            }
            
            return markdownString
        }
    }
}

extension MarkdownViewer.Interactor: MarkdownViewer.BusinessLogic {
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        let markdownString = self.getMarkdownString()
        let response = Event.ViewDidLoad.Response(markdownString: markdownString)
        self.presenter.presentViewDidLoad(response: response)
    }
}
