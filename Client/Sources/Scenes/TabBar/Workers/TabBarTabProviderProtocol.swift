import Foundation
import RxSwift

protocol TabBarTabProviderProtocol {

    var tabs: [TabBar.Model.TabItem] { get }

    func observeTabs() -> Observable<[TabBar.Model.TabItem]>
}

extension TabBar {
    typealias TabProviderProtocol = TabBarTabProviderProtocol
}
