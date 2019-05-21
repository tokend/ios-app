import UIKit
import RxCocoa
import RxSwift

public protocol SaleDetailsDisplayLogic: class {
    
    func displayTabsUpdated(viewModel: SaleDetails.Event.OnTabsUpdated.ViewModel)
}

extension SaleDetails {
    
    public typealias DisplayLogic = SaleDetailsDisplayLogic
    
    public class ViewController: UIViewController {
        
        // MARK: - Private properties
        
        private let containerView: UIScrollView = UIScrollView()
        private var contents: [UIView] = []
        
        private let disposeBag = DisposeBag()
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        
        public func inject(interactorDispatch: InteractorDispatch?, routing: Routing?) {
            self.interactorDispatch = interactorDispatch
            self.routing = routing
        }
        
        // MARK: - Overridden
        
        public override func viewDidLoad() {
            super.viewDidLoad()
            
            self.setupView()
            self.setupContainerView()
            self.setupLayout()
            
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                let request = Event.OnViewDidLoad.Request()
                businessLogic.onViewDidLoad(request: request)
            })
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.containerBackgroundColor
        }
        
        private func setupContainerView() {
            self.containerView.backgroundColor = Theme.Colors.containerBackgroundColor
        }
        
        private func setupLayout() {
            self.view.addSubview(self.containerView)
            
            self.containerView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
        
        private func changeContentViews(views: [UIView]) {
            self.cleanContentViews()
            
            self.contents = views
            
            self.relayoutContents()
        }
        
        private func relayoutContents() {
            var previousView: UIView?
            for view in self.contents {
                self.containerView.addSubview(view)
                view.snp.remakeConstraints { (make) in
                    make.leading.trailing.equalToSuperview()
                    make.width.equalTo(self.view)
                    if let prev = previousView {
                        make.top.equalTo(prev.snp.bottom)
                    } else {
                        make.top.equalToSuperview()
                    }
                }
                
                previousView = view
            }
            
            previousView?.snp.makeConstraints({ (make) in
                make.bottom.equalToSuperview()
            })
        }
        
        private func cleanContentViews() {
            for view in self.contents {
                view.removeFromSuperview()
            }
            self.contents = []
        }
        
        private func getContentView(from contentViewModel: Any) -> UIView {
            let content: UIView
            
            if let sectionsViewModel = contentViewModel as? SaleDetails.GeneralContent.ViewModel {
                let view = SaleDetails.GeneralContent.View()
                sectionsViewModel.setup(view)
                
                content = view
            } else if let tokenViewModel = contentViewModel as? SaleDetails.TokenContent.ViewModel {
                let view = SaleDetails.TokenContent.View()
                tokenViewModel.setup(view)
                
                content = view
            } else if let emptyViewModel = contentViewModel as? SaleDetails.EmptyContent.ViewModel {
                let view = SaleDetails.EmptyContent.View()
                emptyViewModel.setup(view)
                
                content = view
            } else {
                let view = SaleDetails.LoadingContent.View()
                
                content = view
            }
            
            return content
        }
    }
}

extension SaleDetails.ViewController: SaleDetails.DisplayLogic {
    
    public func displayTabsUpdated(viewModel: SaleDetails.Event.OnTabsUpdated.ViewModel) {
        let views = viewModel.contentViewModels.map { (contentModel) -> UIView in
            return self.getContentView(from: contentModel)
        }
        self.changeContentViews(views: views)
    }
}
