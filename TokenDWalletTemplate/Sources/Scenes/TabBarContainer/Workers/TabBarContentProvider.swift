import Foundation

public protocol TabBarContainerContentProviderProtocol {
    func getSceneContent() -> TabBarContainer.Model.SceneContent
}

extension TabBarContainer {
    
    public typealias ContentProviderProtocol = TabBarContainerContentProviderProtocol
}
