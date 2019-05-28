import Foundation

protocol TabBarTabProviderProtocol {
    func getTabs() -> [TabBar.Model.TabItem]
}

extension TabBar {
    typealias TabProviderProtocol = TabBarTabProviderProtocol
}
