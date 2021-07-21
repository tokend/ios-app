import Foundation

public protocol TabBarPresentationLogic {
    typealias Event = TabBar.Event
    
    func presentSceneDidUpdate(response: Event.SceneDidUpdate.Response)
    func presentSceneDidUpdateSync(response: Event.SceneDidUpdateSync.Response)
}

extension TabBar {
    public typealias PresentationLogic = TabBarPresentationLogic
    
    @objc(TabBarPresenter)
    public class Presenter: NSObject {
        
        public typealias Event = TabBar.Event
        public typealias Model = TabBar.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        
        // MARK: -
        
        public init(presenterDispatch: PresenterDispatch) {
            self.presenterDispatch = presenterDispatch
        }
    }
}

private extension TabBar.Presenter {
    
    func sceneViewModel(
        from sceneModel: Model.SceneModel
    ) -> Model.SceneViewModel {
        
        let tabs = sceneModel.tabs.mapToItems(with: sceneModel.selectedTabIdentifier)
        return .init(
            tabs: tabs,
            selectedTab: tabs.first { $0.identifier == sceneModel.selectedTabIdentifier }
        )
    }
}

extension TabBar.Presenter: TabBar.PresentationLogic {
    
    public func presentSceneDidUpdate(response: Event.SceneDidUpdate.Response) {
        let viewModel: Event.SceneDidUpdate.ViewModel = .init(
            viewModel: sceneViewModel(from: response.sceneModel),
            animated: response.animated
        )
        presenterDispatch.display { (displayLogic) in
            displayLogic.displaySceneDidUpdate(viewModel: viewModel)
        }
    }
    
    public func presentSceneDidUpdateSync(response: Event.SceneDidUpdateSync.Response) {
        let viewModel: Event.SceneDidUpdateSync.ViewModel = .init(
            viewModel: sceneViewModel(from: response.sceneModel),
            animated: response.animated
        )
        presenterDispatch.displaySync { (displayLogic) in
            displayLogic.displaySceneDidUpdateSync(viewModel: viewModel)
        }
    }
}

private extension Array where Element == TabBar.Model.TabItem {

    func mapToItems(
        with selectedTabIdentifier: TabBar.Model.TabIdentifier?
    ) -> [TabBar.TabBarItem] {
        map { $0.mapToItem(with: selectedTabIdentifier) }
    }
}

private extension TabBar.Model.TabItem {

    func mapToItem(
        with selectedTabIdentifier: TabBar.Model.TabIdentifier?
    ) -> TabBar.TabBarItem {
        
        return .init(
            title: title,
            image: image,
            identifier: identifier
        )
    }
}
