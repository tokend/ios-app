import UIKit
import RxSwift
import RxCocoa

enum DashboardPlugInType {
    case view(UIView)
    case viewController(UIViewController)
}

protocol DashboardPlugInProtocol {
    var type: DashboardPlugInType { get }
    
    func reloadData()
}

protocol DashboardPlugInsProviderProtocol {
    typealias PlugIn = DashboardPlugInProtocol
    
    func observePlugIns() -> Observable<[PlugIn]>
}

extension DashboardScene {
    typealias PlugIn = DashboardPlugInProtocol
    typealias PlugInsProviderProtocol = DashboardPlugInsProviderProtocol
}
