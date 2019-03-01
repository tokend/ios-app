import Foundation

protocol MarkdownViewerPresentationLogic {
    
    typealias Event = MarkdownViewer.Event
    
    func presentViewDidLoad(response: Event.ViewDidLoad.Response)
}

extension MarkdownViewer {
    
    typealias PresentationLogic = MarkdownViewerPresentationLogic
    
    class Presenter {
        
        typealias Event = MarkdownViewer.Event
        typealias Model = MarkdownViewer.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        
        // MARK: -
        
        init(presenterDispatch: PresenterDispatch) {
            self.presenterDispatch = presenterDispatch
        }
    }
}

extension MarkdownViewer.Presenter: MarkdownViewer.PresentationLogic {
    
    func presentViewDidLoad(response: Event.ViewDidLoad.Response) {
        let viewModel: Event.ViewDidLoad.ViewModel = response
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayViewDidLoad(viewModel: viewModel)
        }
    }
}
