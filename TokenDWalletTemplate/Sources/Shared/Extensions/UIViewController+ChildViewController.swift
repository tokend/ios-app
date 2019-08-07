import UIKit

extension UIViewController {
    func addChildViewController(_ childController: UIViewController, to containerView: UIView) {
        self.addChild(childController)
        containerView.addSubview(childController.view)
        childController.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        childController.didMove(toParent: self)
    }
    
    func removeChildViewController(_ childController: UIViewController) {
        childController.willMove(toParent: nil)
        childController.view.removeFromSuperview()
        childController.removeFromParent()
    }
}
