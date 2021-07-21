import UIKit

public protocol TabContentContainerDisplayLogic: class {
    
    typealias Event = TabContentContainer.Event
}

extension TabContentContainer {
    
    public typealias DisplayLogic = TabContentContainerDisplayLogic
    
    @objc(TabContentContainerViewController)
    public class ViewController: BaseViewController {
        
        public typealias Event = TabContentContainer.Event
        public typealias Model = TabContentContainer.Model

        enum Animation {
            case leftToRight
            case rightToLeft
            case none
        }
        
        // MARK: - Private properties

        private var currentContent: UIViewController? {
            didSet {
                setNeedsStatusBarAppearanceUpdate()
            }
        }
        
        public override var childForStatusBarStyle: UIViewController? {
            currentContent
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
        
        // MARK: - Overridden
        
        public override func viewDidLoad() {
            super.viewDidLoad()
            
            self.setupView()
        }
        
        // MARK: - Private
        
        private func setupView() { }
    }
}

// MARK: - Public methods

extension TabContentContainer.ViewController {

    func setContent(
        _ content: UIViewController,
        animation: Animation
    ) {

        let previousContent = currentContent
        currentContent = content

        addChild(content)
        view.addSubview(content.view)

        if let previous = previousContent {
            let animations: () -> Void

            switch animation {

            case .leftToRight:
                content.view.snp.remakeConstraints { (make) in
                    make.top.bottom.equalToSuperview()
                    make.leading.equalTo(view.snp.trailing)
                    make.width.equalToSuperview()
                }
                view.layoutIfNeeded()

                animations = {
                    content.view.snp.remakeConstraints { (make) in
                        make.edges.equalToSuperview()
                    }

                    previous.view.snp.remakeConstraints { (make) in
                        make.top.bottom.equalToSuperview()
                        make.trailing.equalTo(self.view.snp.leading)
                        make.width.equalToSuperview()
                    }

                    self.view.layoutIfNeeded()
                }

            case .rightToLeft:
                content.view.snp.remakeConstraints { (make) in
                    make.top.bottom.equalToSuperview()
                    make.trailing.equalTo(view.snp.leading)
                    make.width.equalToSuperview()
                }
                view.layoutIfNeeded()

                animations = {
                    content.view.snp.remakeConstraints { (make) in
                        make.edges.equalToSuperview()
                    }

                    previous.view.snp.remakeConstraints { (make) in
                        make.top.bottom.equalToSuperview()
                        make.leading.equalTo(self.view.snp.trailing)
                        make.width.equalToSuperview()
                    }

                    self.view.layoutIfNeeded()
                }

            case .none:
                content.view.snp.remakeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
                view.layoutIfNeeded()
                animations = { }
            }
            
            UIView.animate(
                withDuration: animation == .none ? 0 : TimeInterval(UINavigationController.hideShowBarDuration),
                delay: 0,
                options: .curveEaseOut,
                animations: animations,
                completion: { [weak self] (_) in
                    content.didMove(toParent: self)
                    if let previous = previousContent {
                        self?.removeChildViewController(previous)
                    }
            })
        } else {
            content.view.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            content.didMove(toParent: self)
            if let previous = previousContent {
                removeChildViewController(previous)
            }
        }
    }
}

extension TabContentContainer.ViewController: TabContentContainer.DisplayLogic { }

extension TabContentContainer.ViewController: TabBarContainerContentProtocol {

    public var viewController: UIViewController {
        return self
    }
}
