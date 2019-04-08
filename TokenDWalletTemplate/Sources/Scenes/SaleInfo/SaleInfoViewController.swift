import UIKit

protocol SaleInfoDisplayLogic: class {
    func displayTabsUpdated(viewModel: SaleInfo.Event.OnTabsUpdated.ViewModel)
    func displayTabDidChange(viewModel: SaleInfo.Event.TabDidChange.ViewModel)
}

extension SaleInfo {
    typealias DisplayLogic = SaleInfoDisplayLogic
    
    class ViewController: UIViewController {
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        private var contentView = UIView()
        
        private let tabPicker = HorizontalPicker()
        
        func inject(interactorDispatch: InteractorDispatch?, routing: Routing?) {
            self.interactorDispatch = interactorDispatch
            self.routing = routing
        }
        
        // MARK: - Overridden
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.setupView()
            self.setupTabPickerView()
            self.setupLayout()
            
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                let request = Event.OnViewDidLoad.Request()
                businessLogic.onViewDidLoad(request: request)
            })
        }
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.containerBackgroundColor
        }
        
        private func setupContentView() {
            self.contentView.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupTabPickerView() {
            self.tabPicker.backgroundColor = Theme.Colors.mainColor
            self.tabPicker.tintColor = Theme.Colors.textOnMainColor
        }
        
        private func setupLayout() {
            self.view.addSubview(self.tabPicker)
            self.view.addSubview(self.contentView)
            
            self.tabPicker.snp.makeConstraints { (make) in
                make.top.left.trailing.equalToSuperview()
            }
            
            self.contentView.snp.makeConstraints { (make) in
                make.leading.trailing.bottom.equalToSuperview()
                make.top.equalTo(self.tabPicker.snp.bottom)
            }
        }
        
        private func updateSelectedTabIfNeeded(index: Int?) {
            if let index = index {
                self.tabPicker.setSelectedItemAtIndex(index, animated: false)
            }
        }
        
        private func changeContentView(view: UIView) {
            self.cleanContentView()
            self.contentView.addSubview(view)
            
            view.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
        
        private func cleanContentView() {
            for subview in self.contentView.subviews {
                subview.removeFromSuperview()
            }
        }
        
        private func getContentView(from contentViewModel: Any) -> UIView {
           if let sectionsViewModel = contentViewModel as? SaleInfo.GeneralContent.ViewModel {
                let view = SaleInfo.GeneralContent.View()
                sectionsViewModel.setup(view)
                return view
            } else if let tokenViewModel = contentViewModel as? SaleInfo.TokenContent.ViewModel {
                let view = SaleInfo.TokenContent.View()
                tokenViewModel.setup(view)
                return view
            } else if let emptyViewModel = contentViewModel as? SaleInfo.EmptyContent.ViewModel {
                let view = SaleInfo.EmptyContent.View()
                emptyViewModel.setup(view)
                return view
            } else {
                let view = SaleInfo.LoadingContent.View()
                return view
            }
        }
    }
}

extension SaleInfo.ViewController: SaleInfo.DisplayLogic {
    func displayTabsUpdated(viewModel: SaleInfo.Event.OnTabsUpdated.ViewModel) {
        let items = viewModel.tabTitles.map({ (title) -> HorizontalPicker.Item in
            return HorizontalPicker.Item(
                title: title,
                enabled: true,
                onSelect: { [weak self] in
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        let request = SaleInfo.Event.TabDidChange.Request(id: title)
                        businessLogic.onTabDidChange(request: request)
                    })
                }
            )
        })
        
        self.tabPicker.items = items
        self.updateSelectedTabIfNeeded(index: viewModel.selectedIndex)
        let view = self.getContentView(from: viewModel.contentViewModel)
        self.changeContentView(view: view)
    }
    
    func displayTabDidChange(viewModel: SaleInfo.Event.TabDidChange.ViewModel) {
        let tab = viewModel.tab
        let contentViewModel = tab.contentViewModel
        let view = self.getContentView(from: contentViewModel)
        self.changeContentView(view: view)
    }
}
