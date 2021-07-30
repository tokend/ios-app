import UIKit

typealias PresentViewControllerClosure = (
    _ vc: UIViewController,
    _ animated: Bool,
    _ completion: (() -> Void)?
    ) -> Void

protocol NavigationControllerProtocol: RootContentProtocol {
    func getViewController() -> UIViewController

    func showProgress()
    func hideProgress()

    func setNavigationBarHidden(_ hidden: Bool, animated: Bool)
    func showErrorMessage(_ errorMessage: String, completion: (() -> Void)?)

    func getPresentViewControllerClosure() -> PresentViewControllerClosure

    func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?)

    var topViewController: UIViewController? { get }
    var viewControllers: [UIViewController] { get }
    
    func setViewControllers(_ viewControllers: [UIViewController], animated: Bool)
    func pushViewController(_ viewController: UIViewController, animated: Bool)
    func popViewController(_ animated: Bool)
    @discardableResult
    func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]?
    func popToRootViewController(animated: Bool) -> [UIViewController]?
}

class NavigationController: UINavigationController {

    // MARK: - Private properties

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activity = UIActivityIndicatorView(style: .whiteLarge)
        return activity
    }()

    private lazy var activityView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.05)
        view.isHidden = true

        let outlineView = UIView()
        outlineView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        outlineView.layer.cornerRadius = 10.0
        outlineView.layer.masksToBounds = true

        view.addSubview(outlineView)
        outlineView.snp.makeConstraints({ (make) in
            make.size.equalTo(80.0)
            make.center.equalToSuperview()
        })

        outlineView.addSubview(self.activityIndicator)
        self.activityIndicator.snp.makeConstraints({ (make) in
            make.center.equalToSuperview()
        })

        self.view.addSubview(view)
        
        view.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview()
        })

        return view
    }()

    // MARK: -

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.customInit()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        self.customInit()
    }

    init() {
        super.init(nibName: nil, bundle: nil)

        self.customInit()
    }

    // MARK: - Overridden

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override var childForStatusBarStyle: UIViewController? {
        viewControllers.last
    }
}

// MARK: - Private methods

private extension NavigationController {
    func customInit() {
        setupNavigationBar()
    }

    func setupNavigationBar() { }
}

extension NavigationController: NavigationControllerProtocol {

    func getViewController() -> UIViewController {
        return self
    }

    func showProgress() {
        self.activityView.isHidden = false
        self.activityIndicator.startAnimating()

        self.view.isUserInteractionEnabled = false
    }

    func hideProgress() {
        self.activityView.isHidden = true
        self.activityIndicator.stopAnimating()

        self.view.isUserInteractionEnabled = true
    }

    func showError(_ title: String, message: String, completion: (() -> Void)?) {
        let alert: UIAlertController = .init(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(
            .init(
                title: Localized(.ok_alert_action),
                style: .cancel,
                handler: { (_) in
                    completion?()
            })
        )

        present(alert, animated: true, completion: nil)
    }

    func showErrorMessage(_ errorMessage: String, completion: (() -> Void)?) {
        let alert: UIAlertController = .init(
            title: nil,
            message: errorMessage,
            preferredStyle: .alert
        )
        alert.addAction(
            .init(
                title: Localized(.ok_alert_action),
                style: .cancel,
                handler: { (_) in
                    completion?()
            })
        )

        present(alert, animated: true, completion: nil)
    }

    func getPresentViewControllerClosure() -> PresentViewControllerClosure {
        return { [weak self] (vc, animated, completion) in
            self?.present(vc, animated: animated, completion: completion)
        }
    }

    func popViewController(_ animated: Bool) {
        self.popViewController(animated: animated)
    }
}

extension NavigationController: RootContentProtocol {
    func getRootContentViewController() -> UIViewController {
        return self
    }
}
