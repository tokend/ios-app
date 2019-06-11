import UIKit
import RxCocoa
import RxSwift

public protocol TabsContainerDisplayLogic: class {
    
    typealias Event = TabsContainer.Event
    
    func displayTabsUpdated(viewModel: Event.TabsUpdated.ViewModel)
    func displayTabWasSelected(viewModel: Event.TabWasSelected.ViewModel)
    func displaySelectedTabChanged(viewModel: Event.SelectedTabChanged.ViewModel)
}

extension TabsContainer {
    
    public typealias DisplayLogic = TabsContainerDisplayLogic
    
    @objc(TabsContainerViewController)
    public class ViewController: UIViewController {
        
        public typealias Event = TabsContainer.Event
        public typealias Model = TabsContainer.Model
        
        // MARK: - Private properties
        
        private let horizontalPicker: HorizontalPicker = HorizontalPicker()
        private let containerView: UIScrollView = UIScrollView()
        private let actionButton: UIButton = UIButton()
        
        private var contents: [Model.TabContent] = []
        private var currentContentIndex: Int? {
            return nil
        }
        private var currentContentOffset: CGPoint?
        private let buttonHeight: CGFloat = 45.0
        
        private let disposeBag = DisposeBag()
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        private var onDeinit: DeinitCompletion = nil
        private var viewConfig: Model.ViewConfig = Model.ViewConfig(
            isPickerHidden: false,
            isTabBarHidden: true,
            actionButtonAppearence: .hidden,
            isScrollEnabled: true
            ) {
            didSet {
                self.updateContainerLayout()
                self.updateActionButton()
            }
        }
        
        public func inject(
            interactorDispatch: InteractorDispatch?,
            viewConfig: Model.ViewConfig,
            routing: Routing?,
            onDeinit: DeinitCompletion = nil
            ) {
            
            self.interactorDispatch = interactorDispatch
            self.viewConfig = viewConfig
            self.routing = routing
            self.onDeinit = onDeinit
        }
        
        // MARK: - Overridden
        
        public override func viewDidLoad() {
            super.viewDidLoad()
            
            self.setupView()
            self.setupHorizontalPicker()
            self.setupContainerView()
            self.setupActionButton()
            self.setupLayout()
            
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        public override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
            UIView.animate(withDuration: 0.5, animations: {
                if let contentOffset = self.currentContentOffset {
                    self.containerView.setContentOffset(
                        contentOffset,
                        animated: false
                    )
                }
            })
        }
        
        // MARK: - Private
        
        private func updateContainerLayout() {
            guard self.view.subviews.contains(self.containerView) else {
                return
            }
            self.containerView.snp.remakeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                
                if self.viewConfig.isPickerHidden {
                    make.top.equalToSuperview()
                } else {
                    make.top.equalTo(self.horizontalPicker.snp.bottom)
                }
                
                switch self.viewConfig.actionButtonAppearence {
                    
                case .hidden:
                    make.bottom.equalTo(self.view.safeArea.bottom)
                    
                case .visible:
                    make.bottom.equalTo(self.actionButton.snp.top)
                }
            }
        }
        
        private func updateActionButton() {
            switch viewConfig.actionButtonAppearence {
                
            case .hidden:
                self.actionButton.isHidden = true
                
            case .visible(let title):
                self.actionButton.isHidden = false
                self.actionButton.setTitle(title, for: .normal)
            }
        }
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.containerBackgroundColor
        }
        
        private func setupHorizontalPicker() {
            self.horizontalPicker.backgroundColor = Theme.Colors.mainColor
            self.horizontalPicker.tintColor = Theme.Colors.darkAccentColor
        }
        
        private func setupContainerView() {
            self.containerView.backgroundColor = Theme.Colors.contentBackgroundColor
            self.containerView.isPagingEnabled = true
            self.containerView.showsHorizontalScrollIndicator = false
            self.containerView.showsVerticalScrollIndicator = false
            self.containerView.isDirectionalLockEnabled = true
            self.containerView.canCancelContentTouches = false
            self.containerView.delaysContentTouches = false
            self.containerView.isScrollEnabled = self.viewConfig.isScrollEnabled
            
            let scheduler = MainScheduler.instance
            self.containerView.rx
                .contentOffset
                .throttle(0.1, scheduler: scheduler)
                .subscribe(onNext: { [weak self] (offset) in
                    guard let tabIndex = self?.tabIndexForContentOffset(offset.x) else {
                        return
                    }
                    
                    let request = Event.TabScrolled.Request(tabIndex: tabIndex)
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onTabScrolled(request: request)
                    })
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupActionButton() {
            self.actionButton.backgroundColor = Theme.Colors.accentColor
            self.actionButton
                .rx
                .tap
                .asDriver()
                .drive(onNext: { [weak self] (_) in
                    self?.routing?.onAction()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupLayout() {
            self.view.addSubview(self.horizontalPicker)
            self.view.addSubview(self.containerView)
            self.view.addSubview(self.actionButton)
            
            self.horizontalPicker.snp.makeConstraints { (make) in
                make.leading.trailing.top.equalToSuperview()
            }
            
            self.containerView.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(self.horizontalPicker.snp.bottom)
                make.bottom.equalTo(self.view.safeArea.bottom)
            }
            
            self.actionButton.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.bottom.equalTo(self.view.safeArea.bottom)
                make.height.equalTo(self.buttonHeight)
            }
        }
        
        private func updateSelectedTabIfNeeded(index: Int?) {
            guard let index = index,
                self.horizontalPicker.selectedItemIndex != index else {
                    return
            }
            self.horizontalPicker.setSelectedItemAtIndex(index, animated: true)
        }
        
        private func setContents(_ contents: [Model.TabContent]) {
            self.removeContents()
            self.contents = contents
            
            var prevContentView: UIView?
            for content in contents {
                switch content {
                    
                case .viewController(let vc):
                    self.addChild(vc, to: self.containerView, layoutFulledge: false)
                    vc.view.snp.makeConstraints { (make) in
                        make.top.bottom.equalToSuperview()
                        make.width.height.equalToSuperview()
                        if let prev = prevContentView {
                            make.leading.equalTo(prev.snp.trailing)
                        } else {
                            make.leading.equalToSuperview()
                        }
                    }
                    prevContentView = vc.view
                }
            }
            
            prevContentView?.snp.makeConstraints({ (make) in
                make.trailing.equalToSuperview()
            })
        }
        
        private func removeContents() {
            for content in self.contents {
                switch content {
                    
                case .viewController(let vc):
                    self.removeChildViewController(vc)
                }
            }
            self.contents = []
        }
        
        private func showContent(_ index: Int?, animated: Bool) {
            let contentOffset = self.contentOffsetForTabIndex(index)
            self.currentContentOffset = CGPoint(x: contentOffset, y: 0.0)
            self.containerView.setContentOffset(
                CGPoint(x: contentOffset, y: 0.0),
                animated: animated
            )
        }
        
        private func contentOffsetForTabIndex(_ tabIndex: Int?) -> CGFloat {
            guard let tabIndex = tabIndex else {
                return 0.0
            }
            
            let tabWidth = self.view.bounds.width
            let offset = tabWidth * CGFloat(tabIndex)
            
            return max(offset, 0.0)
        }
        
        private func tabIndexForContentOffset(_ contentOffset: CGFloat) -> Int {
            guard contentOffset >= 0.0 else {
                return 0
            }
            
            let tabWidth = self.view.bounds.width
            let tabIndex = Int(round(contentOffset / tabWidth))
            
            return tabIndex
        }
    }
}

extension TabsContainer.ViewController: TabsContainer.DisplayLogic {
    
    public func displayTabsUpdated(viewModel: Event.TabsUpdated.ViewModel) {
        let items = viewModel.tabs.map { (tab) -> HorizontalPicker.Item in
            return HorizontalPicker.Item(
                title: tab.title,
                enabled: true,
                onSelect: { [weak self] in
                    let request = Event.TabWasSelected.Request(identifier: tab.identifier)
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onTabWasSelected(request: request)
                    })
                }
            )
        }
        self.horizontalPicker.items = items
        self.updateSelectedTabIfNeeded(index: viewModel.selectedTabIndex)
        let contents = viewModel.tabs.map { (tab) -> Model.TabContent in
            return tab.content
        }
        self.setContents(contents)
        self.showContent(viewModel.selectedTabIndex, animated: false)
    }
    
    public func displayTabWasSelected(viewModel: Event.TabWasSelected.ViewModel) {
        self.showContent(viewModel.selectedTabIndex, animated: true)
    }
    
    public func displaySelectedTabChanged(viewModel: Event.SelectedTabChanged.ViewModel) {
        self.updateSelectedTabIfNeeded(index: viewModel.selectedTabIndex)
    }
}

extension TabsContainer.ViewController: TabBarContainerContentProtocol {
    
    public func setContentWithIdentifier(_ identifier: TabBarContainer.TabIdentifier) {
        let request = Event.TabWasSelected.Request(identifier: identifier)
        self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
            businessLogic.onTabWasSelected(request: request)
        })
    }
    
    public var viewController: UIViewController {
        return self
    }
}
