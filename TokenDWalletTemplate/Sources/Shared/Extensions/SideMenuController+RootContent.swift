import UIKit
import SideMenuController

extension SideMenuController: RootContentProtocol {
    func getRootContentViewController() -> UIViewController {
        return self
    }
}
