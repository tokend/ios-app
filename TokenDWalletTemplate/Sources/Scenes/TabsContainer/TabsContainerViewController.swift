import UIKit

public protocol TabsContainerDisplayLogic: class {
    
    typealias Event = TabsContainer.Event
    
    func displayTabsUpdated(viewModel: Event.TabsUpdated.ViewModel)
    func displayTabWasSelected(viewModel: Event.TabWasSelected.ViewModel)
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
        
        private var contents: [Model.TabContent] = []
        private var currentContentIndex: Int? {
            return nil
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
            self.setupHorizontalPicker()
            self.setupContainerView()
            self.setupLayout()
            
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.containerBackgroundColor
        }
        
        private func setupHorizontalPicker() {
            self.horizontalPicker.backgroundColor = Theme.Colors.mainColor
            self.horizontalPicker.tintColor = Theme.Colors.textOnMainColor
        }
        
        private func setupContainerView() {
            self.containerView.backgroundColor = Theme.Colors.contentBackgroundColor
            self.containerView.isPagingEnabled = true
            self.containerView.showsHorizontalScrollIndicator = false
            self.containerView.showsVerticalScrollIndicator = false
        }
        
        private func setupLayout() {
            self.view.addSubview(self.horizontalPicker)
            self.view.addSubview(self.containerView)
            self.horizontalPicker.snp.makeConstraints { (make) in
                make.leading.trailing.top.equalToSuperview()
            }
            
            self.containerView.snp.makeConstraints { (make) in
                make.leading.trailing.bottom.equalToSuperview()
                make.top.equalTo(self.horizontalPicker.snp.bottom)
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
                        make.width.height.equalTo(self.view)
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
        
        private func showContent(_ index: Int?) {
            
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
        self.showContent(viewModel.selectedTabIndex)
    }
    
    public func displayTabWasSelected(viewModel: Event.TabWasSelected.ViewModel) {
        self.showContent(viewModel.selectedTabIndex)
    }
}
