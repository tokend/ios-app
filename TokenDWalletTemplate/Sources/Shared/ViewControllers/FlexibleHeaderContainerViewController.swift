import UIKit

// MARK: - FlexibleHeaderContainerHeaderViewProtocol

protocol FlexibleHeaderContainerHeaderViewProtocol {
    
    typealias OnTitleTextDidChangeCallback = (String) -> Void
    typealias OnTitleAlphaDidChangeCallback = (CGFloat) -> Void
    
    var view: UIView { get } // should be the same between calls
    
    var titleTextDidChange: OnTitleTextDidChangeCallback? { get set }
    var titleAlphaDidChange: OnTitleAlphaDidChangeCallback? { get set }
    
    var minimumHeight: CGFloat { get } // should not be changed
    var maximumHeight: CGFloat { get } // should not be changed
    
    var collapsePercentage: CGFloat { get set } // should not be changed from inside
}

// MARK: - FlexibleHeaderContainerContentViewControllerProtocol

protocol FlexibleHeaderContainerContentViewControllerProtocol {
    
    typealias OnScrollViewDidScroll = (_ scrollView: UIScrollView, _ toTop: Bool) -> Void
    typealias OnScrollViewDidEndScrolling = (_ scrollView: UIScrollView) -> Void
    
    var viewController: UIViewController { get } // should be the same between calls
    
    var scrollViewDidScroll: OnScrollViewDidScroll? { get set }
    var scrollViewDidEndScrolling: OnScrollViewDidEndScrolling? { get set }
    
    func setTopContentInset(_ inset: CGFloat)
    func setMinimumTopContentInset(_ inset: CGFloat)
}

// MARK: - FlexibleHeaderContainerViewController

class FlexibleHeaderContainerViewController: UIViewController {
    
    typealias HeaderViewProtocol = FlexibleHeaderContainerHeaderViewProtocol
    typealias ContentViewControllerProtocol = FlexibleHeaderContainerContentViewControllerProtocol
    
    // MARK: - Private properties
    
    private let titleLabel: UILabel = UILabel()
    private var scrolledToTop: Bool = false
    
    // MARK: - Public properties
    
    public var headerView: HeaderViewProtocol? {
        didSet {
            if oldValue?.view != self.headerView?.view {
                oldValue?.view.removeFromSuperview()
            }
            
            self.setupHeaderView()
        }
    }
    
    public var contentViewController: ContentViewControllerProtocol? {
        didSet {
            if oldValue?.viewController != self.contentViewController?.viewController,
                let old = oldValue?.viewController {
                self.removeChildViewController(old)
            }
            
            self.setupContentViewController()
        }
    }
    
    // MARK: - Overridden
    
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
    }
    
    private func setupTitleLabel() {
        self.titleLabel.font = Theme.Fonts.navigationBarBoldFont
        self.titleLabel.textAlignment = .center
        self.titleLabel.textColor = Theme.Colors.textOnMainColor
        self.navigationItem.titleView = self.titleLabel
    }
    
    private func setupHeaderView() {
        guard var headerView = self.headerView else { return }
        
        headerView.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(headerView.view)
        self.layoutHeaderView()
        self.updateSubviews()
        
        headerView.titleAlphaDidChange = { [weak self] (alpha) in
            let titleAlpha = min(1, max(0, alpha))
            let fromColor = titleAlpha == 0 ? UIColor.clear : Theme.Colors.mainColor
            self?.titleLabel.textColor = UIColor.interpolate(
                from: fromColor,
                to: Theme.Colors.textOnMainColor,
                with: titleAlpha
            )
        }
        headerView.titleTextDidChange = { [weak self] (text) in
            self?.titleLabel.text = text
            self?.titleLabel.sizeToFit()
        }
    }
    
    private func setupContentViewController() {
        guard var contentViewController = self.contentViewController else { return }
        
        self.addChild(
            contentViewController.viewController,
            to: self.view,
            layoutFulledge: true
        )
        self.updateSubviews()
        
        contentViewController.scrollViewDidScroll = { [weak self] (scrollView, toTop) in
            self?.scrolledToTop = toTop
            self?.onScrollViewDidScroll(scrollView: scrollView)
        }
        contentViewController.scrollViewDidEndScrolling = { [weak self] (scrollView) in
            self?.snapHeader(scrollView: scrollView)
        }
    }
    
    private func layoutHeaderView() {
        guard let headerView = self.headerView else { return }
        
        let minHeight = headerView.minimumHeight
        let maxHeight = headerView.maximumHeight
        let diff = maxHeight - minHeight
        let percentage = headerView.collapsePercentage
        
        let headerHeight = minHeight + diff * percentage
        
        let headerFrame = CGRect(
            x: 0.0, y: 0.0,
            width: self.view.bounds.width, height: headerHeight
        )
        headerView.view.frame = headerFrame
    }
    
    private func updateSubviews() {
        if let headerView = self.headerView?.view {
            self.view.bringSubviewToFront(headerView)
        }
        if let contentView = self.contentViewController?.viewController.view {
            self.view.sendSubviewToBack(contentView)
        }
        
        if let headerMaxHeight = self.headerView?.maximumHeight {
            self.contentViewController?.setTopContentInset(headerMaxHeight)
        }
        if let headerMinHeight = self.headerView?.minimumHeight {
            self.contentViewController?.setMinimumTopContentInset(headerMinHeight)
        }
    }
    
    private func onScrollViewDidScroll(scrollView: UIScrollView) {
        guard var headerView = self.headerView else { return }
        
        let minHeight = headerView.minimumHeight
        let maxHeight = headerView.maximumHeight
        let heightDiff = maxHeight - minHeight
        
        let headerMaxHeight = self.headerView?.maximumHeight ?? 0.0
        let offsetDiff = heightDiff - scrollView.contentOffset.y - headerMaxHeight
        let percentage = max(min(offsetDiff / (heightDiff > 0.0 ? heightDiff : 1.0), 1.0), 0.0)
        
        headerView.collapsePercentage = percentage
        self.layoutHeaderView()
    }
    
    private func snapHeader(scrollView: UIScrollView) {
        let minHeight: CGFloat
        let maxHeight: CGFloat
        let collapsePercentage: CGFloat
        
        if let headerView = self.headerView {
            minHeight = headerView.minimumHeight
            maxHeight = headerView.maximumHeight
            collapsePercentage = headerView.collapsePercentage
        } else {
            minHeight = 0.0
            maxHeight = 0.0
            collapsePercentage = 0.0
        }
        
        let percentage: CGFloat = max(min(collapsePercentage, 1.0), 0.0)
        
        let currentOffset = scrollView.contentOffset.y
        var newOffset: CGFloat?
        
        if currentOffset < 0.0 {
            if self.scrolledToTop && percentage != 0.0 {
                newOffset = -maxHeight
            } else if !self.scrolledToTop && percentage != 1.0 {
                newOffset = -minHeight
            }
        }
        
        if let newOffset = newOffset, newOffset != currentOffset {
            let contentOffset = CGPoint(x: scrollView.contentOffset.x, y: newOffset)
            scrollView.setContentOffset(contentOffset, animated: true)
        }
    }
}
