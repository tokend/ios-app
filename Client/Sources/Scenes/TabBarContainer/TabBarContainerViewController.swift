import UIKit

public protocol TabBarContainerDisplayLogic: AnyObject {
    typealias Event = TabBarContainer.Event
}

public protocol TabBarContainerTabBarProtocol {
    var view: UIView { get }
    var height: CGFloat { get }
}

public protocol TabBarContainerContentProtocol {
    var viewController: UIViewController { get }
}

extension TabBarContainer {
    public typealias DisplayLogic = TabBarContainerDisplayLogic
    public typealias TabBarProtocol = TabBarContainerTabBarProtocol
    public typealias ContentProtocol = TabBarContainerContentProtocol
    public typealias TabIdentifier = String
    
    @objc(TabBarContainerViewController)
    public class ViewController: BaseViewController {
        
        public typealias Event = TabBarContainer.Event
        public typealias Model = TabBarContainer.Model
        
        // MARK: - Public properties
        
        public var content: ContentProtocol? {
            didSet {
                if oldValue?.viewController != self.content?.viewController {
                    oldValue?.viewController.removeFromParent()
                    self.setupContent()
                    setNeedsStatusBarAppearanceUpdate()
                    updateAdditionalSafeAreaInsets()
                }
            }
        }
        
        public var tabBar: TabBarProtocol? {
            didSet {
                if oldValue?.view != self.tabBar?.view {
                    oldValue?.view.removeFromSuperview()
                    self.setupTabBar()
                    updateAdditionalSafeAreaInsets()
                }
            }
        }
        
        public override var childForStatusBarStyle: UIViewController? {
            content?.viewController
        }
        
        public override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            
            updateAdditionalSafeAreaInsets()
        }
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        private var onDeinit: DeinitCompletion = nil
        
        public func inject(
            interactorDispatch: InteractorDispatch?,
            routing: Routing?,
            onDeinit: DeinitCompletion = nil
            ) {
            
            self.interactorDispatch = interactorDispatch
            self.routing = routing
            self.onDeinit = onDeinit
        }
        
        // MARK: - Private
        
        private func setupView() { }
        
        private func setupTabBar() {
            guard let tabBar = self.tabBar?.view else { return }
            self.view.addSubview(tabBar)
            self.layoutTabBar()
            self.updateSubviews()
        }
        
        private func setupContent() {
            guard let viewController = self.content?.viewController else { return }
            self.addChild(
                viewController,
                to: self.view,
                layoutFulledge: false
            )
            self.updateSubviews()
        }
        
        private func layoutTabBar() {
            guard let tabBar = self.tabBar?.view else { return }
            
            tabBar.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.bottom.equalToSuperview()
            }
        }
        
        private func updateSubviews() {
            if let tabBar = self.tabBar?.view {
                self.view.bringSubviewToFront(tabBar)
            }
            
            guard let viewController = self.content?.viewController else { return }
            
            self.view.sendSubviewToBack(viewController.view)
            viewController.view.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
        
        func updateAdditionalSafeAreaInsets() {
            if let tabBar = tabBar {
                content?.viewController.additionalSafeAreaInsets.bottom = tabBar.height - view.safeAreaInsets.bottom
            } else {
                content?.viewController.additionalSafeAreaInsets.bottom = 0
            }
        }
    }
}

extension TabBarContainer.ViewController: TabBarContainer.DisplayLogic { }

extension TabBarContainer.ViewController: RootContentProtocol {
    func getRootContentViewController() -> UIViewController {
        return self
    }
}
