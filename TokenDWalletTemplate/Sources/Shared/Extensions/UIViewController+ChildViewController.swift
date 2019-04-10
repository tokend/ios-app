import UIKit

extension UIViewController {
    
    func addChild(
        _ childController: UIViewController,
        to containerView: UIView,
        layoutFulledge: Bool
        ) {
        
        self.addChild(childController)
        containerView.addSubview(childController.view)
        if layoutFulledge {
            childController.view.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
        childController.didMove(toParent: self)
    }
    
    func removeChildViewController(
        _ childController: UIViewController
        ) {
        
        childController.willMove(toParent: nil)
        childController.view.removeFromSuperview()
        childController.removeFromParent()
    }
}
