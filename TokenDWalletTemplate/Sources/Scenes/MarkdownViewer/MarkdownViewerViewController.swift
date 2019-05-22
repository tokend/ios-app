import UIKit
import MarkdownView

protocol MarkdownViewerDisplayLogic: class {
    
    typealias Event = MarkdownViewer.Event
    
    func displayViewDidLoad(viewModel: Event.ViewDidLoad.ViewModel)
}

extension MarkdownViewer {
    
    typealias DisplayLogic = MarkdownViewerDisplayLogic
    
    class ViewController: UIViewController {
        
        typealias Event = MarkdownViewer.Event
        typealias Model = MarkdownViewer.Model
        
        // MARK: - Private
        
        private var markdownView: MarkdownView? {
            didSet {
                oldValue?.removeFromSuperview()
                self.layoutMarkdwonView()
            }
        }
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        private var onDeinit: DeinitCompletion = nil
        
        func inject(
            interactorDispatch: InteractorDispatch?,
            routing: Routing?,
            onDeinit: DeinitCompletion = nil
            ) {
            
            self.interactorDispatch = interactorDispatch
            self.routing = routing
            self.onDeinit = onDeinit
        }
        
        // MARK: - Overridden
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.setupView()
            
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.containerBackgroundColor
        }
        
        private func showMarkdownString(_ markdownString: String) {
            self.markdownView = MarkdownView()
            self.markdownView?.load(markdown: markdownString)
        }
        
        private func layoutMarkdwonView() {
            guard let markdownView = self.markdownView else { return }
            
            self.view.addSubview(markdownView)
            markdownView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }
}

extension MarkdownViewer.ViewController: MarkdownViewer.DisplayLogic {
    
    func displayViewDidLoad(viewModel: Event.ViewDidLoad.ViewModel) {
        self.showMarkdownString(viewModel.markdownString)
    }
}
