import UIKit

class HorizontalPicker: UIView {
    
    struct Item {
        let title: String
        let enabled: Bool
        let onSelect: () -> Void
    }
    
    // MARK: - Private properties
    
    private let scrollView: UIScrollView = UIScrollView()
    private let segmentedControl: UISegmentedControl = UISegmentedControl()
    
    private let sideInset: CGFloat = 15
    private let topInset: CGFloat = 8
    private var bottomInset: CGFloat {
        return self.topInset + 1
    }
    
    // MARK: - Public properties
    
    public var items: [Item] = [] {
        didSet {
            self.updateItems()
        }
    }
    
    public var selectedItemIndex: Int {
        return self.segmentedControl.selectedSegmentIndex
    }
    
    override var backgroundColor: UIColor? {
        didSet {
            self.scrollView.backgroundColor = self.backgroundColor
            self.segmentedControl.backgroundColor = self.backgroundColor
        }
    }
    
    override var tintColor: UIColor! {
        didSet {
            self.segmentedControl.tintColor = self.tintColor
        }
    }
    
    // MARK: -
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        let width = self.segmentedControl.frame.width + 2 * self.sideInset
        let height = self.segmentedControl.frame.height + self.topInset + self.bottomInset
        return CGSize(width: width, height: height)
    }
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
        ) {
        
        guard let scrollView = object as? UIScrollView,
            self.scrollView == scrollView,
            keyPath == Localized(.bounds)
            else {
                super.observeValue(
                    forKeyPath: keyPath,
                    of: object,
                    change: change,
                    context: context
                )
                return
        }
        
        let newValue = (change?[.newKey] as? CGRect)?.width
        let oldValue = (change?[.oldKey] as? CGRect)?.width
        if newValue != oldValue {
            self.relayoutSegmentedControl()
            self.scrollToSegmentAtIndexIfNeeded(
                self.segmentedControl.selectedSegmentIndex,
                animated: false
            )
        }
    }
    
    // MARK: - Public
    
    public func setSelectedItemAtIndex(_ index: Int, animated: Bool) {
        self.segmentedControl.selectedSegmentIndex = index
        self.relayoutSegmentedControl()
        self.scrollToSegmentAtIndexIfNeeded(index, animated: animated)
    }
    
    // MARK: - Private
    
    private func commonInit() {
        self.setupView()
        self.setupScrollView()
        self.setupSegmentedControl()
        
        self.setupLayout()
    }
    
    private func setupView() { }
    
    private func setupScrollView() {
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.alwaysBounceHorizontal = false
        self.scrollView.alwaysBounceVertical = false
        self.scrollView.contentInset = UIEdgeInsets(
            top: self.topInset,
            left: self.sideInset,
            bottom: self.bottomInset,
            right: self.sideInset
        )
        self.scrollView.keyboardDismissMode = .none
        self.scrollView.addObserver(
            self,
            forKeyPath: Localized(.bounds),
            options: [.new, .old],
            context: nil
        )
    }
    
    private func setupSegmentedControl() {
        self.segmentedControl.addTarget(
            self,
            action: #selector(self.segmentedControlValueChanged),
            for: .valueChanged
        )
    }
    
    @objc private func segmentedControlValueChanged() {
        let index = self.segmentedControl.selectedSegmentIndex
        guard self.items.indexInBounds(index) else {
            return
        }
        
        self.items[index].onSelect()
        self.scrollToSegmentAtIndexIfNeeded(index, animated: true)
    }
    
    private func setupLayout() {
        self.addSubview(self.scrollView)
        self.scrollView.addSubview(self.segmentedControl)
        
        self.scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        self.segmentedControl.snp.makeConstraints { (make) in
            make.height.equalTo(self.scrollView.snp.height).inset(self.bottomInset)
            make.width.greaterThanOrEqualTo(self.scrollView.snp.width).inset(self.sideInset)
            make.edges.equalToSuperview()
        }
    }
    
    private func relayoutSegmentedControl() {
        self.segmentedControl.setNeedsLayout()
        self.segmentedControl.superview?.layoutIfNeeded()
    }
    
    private func updateItems() {
        let titles = self.items.map { (item) -> String in
            return item.title
        }
        self.segmentedControl.fillWithSegments(titles, animated: false)
        
        for item in self.items.enumerated() {
            self.segmentedControl.setEnabled(item.element.enabled, forSegmentAt: item.offset)
        }
        
        self.relayoutSegmentedControl()
    }
    
    private func scrollToSegmentAtIndexIfNeeded(_ index: Int, animated: Bool) {
        let segmentedControlWidth: CGFloat = self.segmentedControl.frame.width
        var numberOfSegments = CGFloat(self.segmentedControl.numberOfSegments)
        if numberOfSegments == 0 {
            numberOfSegments = 1
        }
        let segmentWidth: CGFloat = segmentedControlWidth / numberOfSegments
        self.scrollToRect(segmentWidth * CGFloat(index), width: segmentWidth, animated: animated)
    }
    
    private enum HorizontalScrollPosition {
        case center
    }
    private func scrollToRect(_ xOffset: CGFloat, width: CGFloat, animated: Bool) {
        let viewRectInScrollView = CGRect(
            x: xOffset,
            y: 0,
            width: width,
            height: self.segmentedControl.frame.width
        )
        
        let horizontalScrollPosition: HorizontalScrollPosition = .center
        let contentOffsetX: CGFloat = {
            switch horizontalScrollPosition {
            case .center:
                let horizontalScrollViewCenterOffset: CGFloat = self.sideInset - self.scrollView.bounds.width / 2
                var offsetX = viewRectInScrollView.midX + horizontalScrollViewCenterOffset
                let minimumXOffset: CGFloat = 0
                let scrollWidthDiff = self.scrollView.contentSize.width - self.scrollView.bounds.width
                let maximumXOffset: CGFloat = scrollWidthDiff + 2 * self.sideInset
                if offsetX < minimumXOffset {
                    offsetX = minimumXOffset
                } else if offsetX > maximumXOffset {
                    offsetX = maximumXOffset
                }
                return offsetX
            }
            }() - self.sideInset
        
        let contentOffsetY: CGFloat = self.scrollView.contentOffset.y
        let newContentOffset = CGPoint(x: contentOffsetX, y: contentOffsetY)
        
        UIView.animate(
            withDuration: animated ? 0.25 : 0,
            animations: {
                self.scrollView.setContentOffset(
                    newContentOffset,
                    animated: false
                )
        })
    }
}
