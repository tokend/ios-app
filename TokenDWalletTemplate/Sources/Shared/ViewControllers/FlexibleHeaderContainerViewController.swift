import UIKit

// MARK: -

protocol FlexibleHeaderContainerHeaderViewProtocol {
    typealias OnTitleTextDidChangeCallback = (String) -> Void
    typealias OnTitleAlphaDidChangeCallback = (CGFloat) -> Void
    typealias OnContentHeightDidChangeCallback = () -> Void
    typealias OnMinimumHeightDidChangeCallback = () -> Void
    
    var titleTextDidChange: OnTitleTextDidChangeCallback? { get set }
    var titleAlphaDidChange: OnTitleAlphaDidChangeCallback? { get set }
    var contentHeightDidChange: OnContentHeightDidChangeCallback? { get set }
    var minimumHeightDidChange: OnMinimumHeightDidChangeCallback? { get set }
    
    var view: UIView { get }
    var maximumHeight: CGFloat { get }
    var minimumHeight: CGFloat { get }
    var stretchFactor: CGFloat { get }
    
    func flexibleHeaderDidChangePercent(_ percent: CGFloat)
}

protocol FlexibleHeaderContainerContentViewControllerProtocol {
    typealias OnScrollViewDidScroll = (_ scrollView: UIScrollView, _ toTop: Bool) -> Void
    typealias OnScrollViewDidEndScrolling = (_ scrollView: UIScrollView) -> Void
    
    var viewController: UIViewController { get }
    
    var scrollViewDidScroll: OnScrollViewDidScroll? { get set }
    var scrollViewDidEndScrolling: OnScrollViewDidEndScrolling? { get set }
    
    func setTopContentInset(_ inset: CGFloat)
    func setMinimumTopContentInset(_ inset: CGFloat)
}

// MARK: -

class FlexibleHeaderContainerViewController: UIViewController {
    
    typealias HeaderViewProtocol = FlexibleHeaderContainerHeaderViewProtocol
    typealias ContentViewControllerProtocol = FlexibleHeaderContainerContentViewControllerProtocol
    
    // MARK: - Private properties
    
    private let titleLabel: UILabel = UILabel()
    private var scrolledToTop: Bool = false
    
    // MARK: - Public properties
    
    public var headerView: HeaderViewProtocol? {
        didSet {
            oldValue?.view.removeFromSuperview()
            self.headerView?.titleAlphaDidChange = { [weak self] (alpha) in
                let titleAlpha = min(1, max(0, alpha))
                let fromColor = titleAlpha == 0 ? UIColor.clear : Theme.Colors.mainColor
                self?.titleLabel.textColor = UIColor.interpolate(
                    from: fromColor,
                    to: Theme.Colors.textOnMainColor,
                    with: titleAlpha
                )
            }
            self.headerView?.titleTextDidChange = { [weak self] (text) in
                self?.titleLabel.text = text
                self?.titleLabel.sizeToFit()
            }
            self.headerView?.contentHeightDidChange = { [weak self] in
                self?.updateScrollViewInsets()
            }
            self.headerView?.minimumHeightDidChange = { [weak self] in
                self?.contentViewController?.setMinimumTopContentInset(self?.headerView?.minimumHeight ?? 0)
            }
            self.layoutHeaderView()
            self.updateScrollViewInsets()
        }
    }
    
    public var contentViewController: ContentViewControllerProtocol? {
        didSet {
            if let old = oldValue {
                self.removeChildViewController(old.viewController)
            }
            self.contentViewController?.scrollViewDidScroll = { [weak self] (scrollView, toTop) in
                self?.scrolledToTop = toTop
                
                let maximumHeight: CGFloat = self?.headerView?.maximumHeight ?? 0.0
                let minimumHeight: CGFloat = self?.headerView?.minimumHeight ?? 0.0
                let collapsibleHeight: CGFloat = maximumHeight - minimumHeight
                let offsetDiff = collapsibleHeight - scrollView.contentOffset.y - scrollView.contentInset.top
                let stretchFactor = max(min(offsetDiff / collapsibleHeight, 1.0), 0.0)
                let percentage = max(min(1.0, stretchFactor), 0.0)
                self?.updateHeaderConstraints(collapsibleHeight * percentage + minimumHeight)
                self?.headerView?.flexibleHeaderDidChangePercent(percentage)
            }
            self.contentViewController?.scrollViewDidEndScrolling = { [weak self] (scrollView) in
                guard let headerView = self?.headerView else { return }
                self?.snapHeader(scrollView: scrollView, headerView: headerView)
            }
            self.updateScrollViewInsets()
            self.layoutContentViewController()
        }
    }
    
    // MARK: -
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private
    
    private func commonInit() {
        self.setupTitleLabel()
        
        self.setupLayout()
    }
    
    private func layoutHeaderView() {
        guard let headerView = self.headerView else {
            return
        }
        self.view.addSubview(headerView.view)
        self.view.sendSubview(toBack: headerView.view)
        
        if let view = self.contentViewController?.viewController.view {
            self.view.sendSubview(toBack: view)
        }
        
        self.updateHeaderConstraints(headerView.maximumHeight)
    }
    
    private func updateHeaderConstraints(_ height: CGFloat) {
        self.headerView?.view.snp.remakeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(height)
        }
    }
    
    private func updateScrollViewInsets() {
        let inset = self.headerView?.maximumHeight ?? 0
        self.contentViewController?.setTopContentInset(inset)
    }
    
    private func layoutContentViewController() {
        guard let controller = self.contentViewController?.viewController else {
            return
        }
        self.addChildViewController(controller, to: self.view)
        self.view.sendSubview(toBack: controller.view)
    }
    
    private func setupTitleLabel() {
        self.titleLabel.font = Theme.Fonts.navigationBarBoldFont
        self.titleLabel.textAlignment = .center
        self.titleLabel.textColor = Theme.Colors.textOnMainColor
    }
    
    private func setupLayout() {
        self.navigationItem.titleView = self.titleLabel
    }
    
    private func snapHeader(scrollView: UIScrollView, headerView: FlexibleHeaderContainerHeaderViewProtocol) {
        let percentage = max(min(1, headerView.stretchFactor), 0)
        let maximumHeight = headerView.maximumHeight
        let minimumHeight = headerView.minimumHeight
        var newYOffset: CGFloat?
        let oldYOffset = scrollView.contentOffset.y
        if oldYOffset < 0 {
            if self.scrolledToTop &&
                percentage != 0 {
                newYOffset = -maximumHeight
            } else if !self.scrolledToTop &&
                percentage != 1 {
                newYOffset = -minimumHeight
            }
        }
        
        if let newYOffset = newYOffset,
            newYOffset != oldYOffset {
            let newOffset = CGPoint(x: scrollView.contentOffset.x, y: newYOffset)
            scrollView.setContentOffset(newOffset, animated: true)
        }
    }
}
