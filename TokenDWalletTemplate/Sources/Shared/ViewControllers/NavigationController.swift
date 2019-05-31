import UIKit

typealias PresentViewControllerClosure = (
    _ vc: UIViewController,
    _ animated: Bool,
    _ completion: (() -> Void)?
    ) -> Void

protocol NavigationControllerProtocol: RootContentProtocol {
    func getViewController() -> UIViewController
    
    var navigationBar: UINavigationBar { get }
    func setNavigationBarHidden(_ hidden: Bool, animated: Bool)
    
    func showShadow()
    func hideShadow()
    
    func showProgress()
    func hideProgress()
    
    func showErrorMessage(_ errorMessage: String, completion: (() -> Void)?)
    
    func getPresentViewControllerClosure() -> PresentViewControllerClosure
    
    func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?)
    
    func setViewControllers(_ viewControllers: [UIViewController], animated: Bool)
    func pushViewController(_ viewController: UIViewController, animated: Bool)
    func popViewController(_ animated: Bool)
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
        return Theme.Colors.statusBarStyleOnMain
    }
    
    // MARK: - Private
    
    private func customInit() {
        self.navigationBar.isTranslucent = false
        self.navigationBar.barTintColor = Theme.Colors.mainColor
        self.navigationBar.tintColor = Theme.Colors.textOnMainColor
        
        self.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: Theme.Fonts.navigationBarBoldFont,
            NSAttributedString.Key.foregroundColor: Theme.Colors.textOnMainColor
        ]
        self.navigationBar.shadowImage = UIImage()
    }
    
    private func setupNavigationBar() {
        self.navigationBar.layer.shadowColor = Theme.Colors.separatorOnMainColor.cgColor
        self.navigationBar.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        self.navigationBar.layer.shadowRadius = 4.0
        self.navigationBar.layer.shadowOpacity = 0.0
        self.navigationBar.layer.masksToBounds = false
    }
}

extension NavigationController: NavigationControllerProtocol {
    
    func getViewController() -> UIViewController {
        return self
    }
    
    func showShadow() {
        self.navigationBar.layer.shadowOpacity = 1.0
    }
    
    func hideShadow() {
        self.navigationBar.layer.shadowOpacity = 0.0
    }
    
    func showProgress() {
        self.activityView.isHidden = false
        self.activityIndicator.startAnimating()
    }
    
    func hideProgress() {
        self.activityView.isHidden = true
        self.activityIndicator.stopAnimating()
    }
    
    func showErrorMessage(_ errorMessage: String, completion: (() -> Void)?) {
        let alert = UIAlertController(
            title: Localized(.error),
            message: errorMessage,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: Localized(.cancel),
            style: .cancel,
            handler: { _ in
                completion?()
        }))
        
        self.present(alert, animated: true, completion: nil)
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
