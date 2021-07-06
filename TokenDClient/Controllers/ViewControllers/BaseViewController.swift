import UIKit

public class BaseViewController: UIViewController {

    // MARK: - Overridden

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.interactivePopGestureRecognizer?.delegate = self
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
    }

    deinit {
        print(.deinit(object: self))
    }
}

extension BaseViewController: UIGestureRecognizerDelegate { }
