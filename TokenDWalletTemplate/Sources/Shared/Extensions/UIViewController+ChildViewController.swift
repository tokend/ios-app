import UIKit

extension UIViewController {
    func addChildViewController(_ childController: UIViewController, to containerView: UIView) {
        self.addChildViewController(childController)
        containerView.addSubview(childController.view)
        childController.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        childController.didMove(toParentViewController: self)
    }
    
    func removeChildViewController(_ childController: UIViewController) {
        childController.willMove(toParentViewController: nil)
        childController.view.removeFromSuperview()
        childController.removeFromParentViewController()
    }
}
