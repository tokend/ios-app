import UIKit
import SnapKit

enum RootNavigationTransition {
    case fade
}

protocol RootNavigationProtocol {
    func setRootContent(
        _ rootContent: RootContentProtocol,
        transition: RootNavigationTransition,
        animated: Bool
    )
    
    func presentAlert(
        _ alertController: UIAlertController,
        animated: Bool,
        completion: (() -> Void)?
    )
    
    func showBackgroundCover()
    func hideBackgroundCover()
}

protocol RootContentProtocol {
    func getRootContentViewController() -> UIViewController
}

class RootNavigationViewController: UIViewController, RootNavigationProtocol {
    
    // MARK: - Private properties
    
    private let contentContainer: UIView = UIView()
    private var currentContent: RootContentProtocol? {
        didSet {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    private let backgroundCover: UIView = UIView()
    
    private var viewAppeared: Bool = false
    
    // MARK: - Public properties
    
    weak var appController: AppController?
    
    // MARK: - RootNavigationProtocol
    
    func setRootContent(
        _ rootContent: RootContentProtocol,
        transition: RootNavigationTransition,
        animated: Bool
        ) {
        
        if animated {
            switch transition {
                
            case .fade:
                self.fadeToNewContent(rootContent)
            }
        } else {
            self.setNewContent(rootContent)
        }
    }
    
    func presentAlert(
        _ alertController: UIAlertController,
        animated: Bool,
        completion: (() -> Void)?
        ) {
        
        self.present(alertController, animated: animated, completion: completion)
    }
    
    func showBackgroundCover() {
        self.backgroundCover.isHidden = false
    }
    
    func hideBackgroundCover() {
        self.backgroundCover.isHidden = true
    }
    
    // MARK: - Overridden
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !self.viewAppeared {
            self.viewAppeared = true
            self.appController?.onRootWillAppear()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    // MARK: - Private
    
    private func setNewContent(_ content: RootContentProtocol) {
        let previous = self.currentContent
        
        let contentViewController = content.getRootContentViewController()
        self.addChild(contentViewController)
        self.contentContainer.addSubview(contentViewController.view)
        contentViewController.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        contentViewController.didMove(toParent: self)
        self.currentContent = content
        
        let previousContentViewController = previous?.getRootContentViewController()
        previousContentViewController?.willMove(toParent: nil)
        previousContentViewController?.view.removeFromSuperview()
        previousContentViewController?.removeFromParent()
    }
    
    private func fadeToNewContent(_ content: RootContentProtocol) {
        let previous = self.currentContent
        
        let fullDuration: TimeInterval = 0.3
        let halfDuration: TimeInterval = fullDuration / 2.0
        
        let contentViewController = content.getRootContentViewController()
        contentViewController.view.alpha = 0.0
        self.addChild(contentViewController)
        self.contentContainer.addSubview(contentViewController.view)
        contentViewController.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        contentViewController.didMove(toParent: self)
        self.currentContent = content
        
        var delay = halfDuration
        if previous != nil {
            UIView.animate(
                withDuration: halfDuration,
                delay: 0.0,
                options: [.curveEaseOut],
                animations: {
                    previous?.getRootContentViewController().view.alpha = 0.0
            },
                completion: { _ in
                    let previousContentViewController = previous?.getRootContentViewController()
                    previousContentViewController?.willMove(toParent: nil)
                    previousContentViewController?.view.removeFromSuperview()
                    previousContentViewController?.removeFromParent()
            })
        } else {
            delay = 0.0
        }
        
        UIView.animate(
            withDuration: halfDuration,
            delay: delay,
            options: [.curveEaseIn],
            animations: {
                contentViewController.view.alpha = 1.0
        },
            completion: nil
        )
    }
    
    // MARK: - Setup
    
    private func setupView() {
        self.view.backgroundColor = Theme.Colors.contentBackgroundColor
        self.contentContainer.backgroundColor = UIColor.clear
        
        self.view.addSubview(self.contentContainer)
        self.contentContainer.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        let launchScreen = UIStoryboard(name: "LaunchScreen", bundle: nil)
        if let launchVC = launchScreen.instantiateInitialViewController(), let launchView = launchVC.view {
            self.addChild(launchVC)
            self.backgroundCover.addSubview(launchView)
            launchVC.didMove(toParent: self)
            launchView.snp.makeConstraints({ (make) in
                make.edges.equalToSuperview()
            })
        }
        self.backgroundCover.backgroundColor = Theme.Colors.contentBackgroundColor
        self.backgroundCover.isHidden = true
        self.view.addSubview(self.backgroundCover)
        self.backgroundCover.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}
