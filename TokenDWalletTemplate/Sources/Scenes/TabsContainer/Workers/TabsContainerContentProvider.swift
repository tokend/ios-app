import Foundation
import RxCocoa
import RxSwift

public protocol TabsContainerContentProviderProtocol {
    
    func observeTabs() -> Observable<[TabsContainer.Model.TabModel]>
}

extension TabsContainer {
    
    public typealias ContentProvider = TabsContainerContentProviderProtocol
    
    public class InfoContentProvider {
        
        // MARK: - Private properties
        
        private let tabs: BehaviorRelay<[Model.TabModel]>
        
        // MARK: -
        
        public init(tabs: [Model.TabModel]) {
            self.tabs = BehaviorRelay(value: tabs)
        }
    }
}

extension TabsContainer.InfoContentProvider: TabsContainer.ContentProvider {
    
    public func observeTabs() -> Observable<[TabsContainer.Model.TabModel]> {
        return self.tabs.asObservable()
    }
}
