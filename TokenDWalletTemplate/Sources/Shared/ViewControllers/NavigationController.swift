import UIKit

protocol NavigationControllerProtocol: RootContentProtocol {
    func getViewController() -> UIViewController
    
    var navigationBar: UINavigationBar { get }
    func setNavigationBarHidden(_ hidden: Bool, animated: Bool)
    
    func showProgress()
    func hideProgress()
    
    func showErrorMessage(_ errorMessage: String, completion: (() -> Void)?)
    
    func showDialog(
        title: String?,
        message: String?,
        style: UIAlertController.Style,
        options: [String],
        onSelected: @escaping (_ selectedIndex: Int) -> Void,
        onCanceled: (() -> Void)?
    )
    
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
    }
}

extension NavigationController: NavigationControllerProtocol {
    func getViewController() -> UIViewController {
        return self
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
            title: "Error",
            message: errorMessage,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { _ in
                completion?()
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func showDialog(
        title: String?,
        message: String?,
        style: UIAlertController.Style,
        options: [String],
        onSelected: @escaping (_ selectedIndex: Int) -> Void,
        onCanceled: (() -> Void)?
        ) {
        
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: style
        )
        
        for (index, option) in options.enumerated() {
            alert.addAction(UIAlertAction(
                title: option,
                style: .default,
                handler: { _ in
                    onSelected(index)
            }))
        }
        
        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { _ in
                onCanceled?()
        }))
        
        self.present(alert, animated: true, completion: nil)
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
