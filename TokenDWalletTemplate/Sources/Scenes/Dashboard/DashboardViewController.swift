import UIKit
import RxSwift
import PullToRefresh

protocol DashboardSceneDisplayLogic: class {
    func displayPlugInsDidChange(viewModel: DashboardScene.Event.PlugInsDidChange.ViewModel)
}

extension DashboardScene {
    typealias DisplayLogic = DashboardSceneDisplayLogic
    
    class ViewController: UIViewController {
        
        // MARK: - Private properties
        
        private let scrollView: UIScrollView = UIScrollView()
        
        private let disposeBag = DisposeBag()
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        
        func inject(interactorDispatch: InteractorDispatch?, routing: Routing?) {
            self.interactorDispatch = interactorDispatch
            self.routing = routing
        }
        
        // MARK: - Overridden
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.setupView()
            self.setupScrollView()
            self.setupBarButtonItem()
            
            self.setupLayout()
            
            let request = DashboardScene.Event.ViewDidLoadSync.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoadSync(request: request)
            }
        }
        
        deinit {
            self.scrollView.removeAllPullToRefresh()
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.containerBackgroundColor
        }
        
        private func setupScrollView() {
            self.scrollView.showsVerticalScrollIndicator = false
            self.scrollView.showsHorizontalScrollIndicator = false
            self.scrollView.alwaysBounceVertical = true
            
            let refresher = self.createRefresher()
            
            self.scrollView.addPullToRefresh(refresher) { [weak self] in
                self?.scrollView.startRefreshing(at: .top)
                let request = DashboardScene.Event.DidInitiateRefresh.Request()
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onDidInitiateRefresh(request: request)
                })
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
                    self?.scrollView.endRefreshing(at: .top)
                }
            }
        }
        
        private func setupBarButtonItem() {
            let rightBarButtonItem = UIBarButtonItem(
                image: Assets.plusIcon.image,
                style: .plain,
                target: nil,
                action: nil
            )
            
            rightBarButtonItem
                .rx
                .tap
                .asDriver()
                .drive(onNext: { [weak self] (_) in
                    self?.routing?.showExploreAssets()
                })
            .disposed(by: self.disposeBag)
            self.navigationItem.rightBarButtonItem = rightBarButtonItem
        }
        
        private func createRefresher() -> PullToRefresh {
            let refresher = PullToRefresh()
            refresher.position = .top
            refresher.shouldBeVisibleWhileScrolling = true
            refresher.animationDuration = TimeInterval(exactly: 1)!
            
            return refresher
        }
        
        private func setupLayout() {
            self.view.addSubview(self.scrollView)
            
            self.scrollView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }
}

extension DashboardScene.ViewController: DashboardScene.DisplayLogic {
    func displayPlugInsDidChange(viewModel: DashboardScene.Event.PlugInsDidChange.ViewModel) {
        for subview in self.scrollView.subviews {
            subview.removeFromSuperview()
        }
        
        var contentViews: [UIView] = []
        
        for view in viewModel.plugIns {
            switch view.type {
            case .view(let view):
                contentViews.append(view)
            case .viewController(let viewController):
                self.addChild(viewController)
                contentViews.append(viewController.view)
                viewController.didMove(toParent: self)
            }
        }
        
        var lastView: UIView?
        for view in contentViews {
            self.scrollView.addSubview(view)
            view.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.width.equalToSuperview()
                if let last = lastView {
                    make.top.equalTo(last.snp.bottom).offset(32)
                } else {
                    make.top.equalToSuperview().inset(24)
                }
            }
            lastView = view
        }
        
        if let last = lastView {
            last.snp.makeConstraints { (make) in
                make.bottom.equalToSuperview().inset(24)
            }
        }
    }
}
