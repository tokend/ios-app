import UIKit

class BXFStaticTableView: UIView {
    
    private let defaultTopInset: CGFloat = 24
    private let defaultBottomInset: CGFloat = 24

    private let scrollView: BXFScrollViewWithKeyboardResponder = BXFScrollViewWithKeyboardResponder()
    private let stackView: UIStackView = UIStackView()
    
    var contentInset: UIEdgeInsets {
        get { return self.scrollView.contentInset }
        set { self.scrollView.contentInset = newValue }
    }
    
//    public var keyboardDismissMode: UIScrollViewKeyboardDismissMode {
//        get {
//            return scrollView.keyboardDismissMode
//        }
//        set {
//            scrollView.keyboardDismissMode = newValue
//        }
//    }
    
//    public var shouldIgnoreKeyboardEvents: Bool = false {
//        didSet {
//            if shouldIgnoreKeyboardEvents {
////                scrollView.removeObservers()
//            } else {
////                scrollView.initKeyboardNotifications()
//            }
//        }
//    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = BXFStaticTableViewAppearance.backgroundColor

        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        scrollView.backgroundColor = UIColor.clear
        self.contentInset = UIEdgeInsets(
            top: defaultTopInset,
            left: 0,
            bottom: defaultBottomInset,
            right: 0)
        addSubview(scrollView)
        scrollView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
            maker.width.equalToSuperview()
        }

        stackView.alignment = .fill
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = BXFStaticTableViewAppearance.space
    }

    public func removeAllObjects() {
        for subview in stackView.arrangedSubviews {
            subview.removeFromSuperview()
        }
    }
    
    public func setTopInset(_ inset: CGFloat) {
        self.contentInset.top = inset
    }
    
    public func addTopInset(_ inset: CGFloat) {
        self.contentInset.top += inset
    }
    
    public func setBottomInset(_ inset: CGFloat) {
        self.contentInset.bottom = inset
    }
    
    public func addBottomInset(_ inset: CGFloat) {
        self.contentInset.bottom += inset
    }
    
//    public func scrollTo(view: UIView, animated: Bool) {
//        scrollView.scrollToViewIfDescendant(view, animated: animated)
//    }
    
    public func createSection(_ section: BXFStaticTableViewSection) -> UIView {
        return BXFStaticTableView.createSection(section)
    }
    
    static func createSection(_ section: BXFStaticTableViewSection) -> UIView {
        let sectionView = UIView()
        
        sectionView.addSubview(section.header)
        sectionView.addSubview(section.footer)
        sectionView.addSubview(section.cell)
        
        section.header.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }
        
        section.cell.snp.makeConstraints { (make) in
            make.top.equalTo(section.header.snp.bottom)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalTo(section.footer.snp.top)
        }
        
        section.footer.snp.makeConstraints { (make) in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        return sectionView
    }
    
    public func createSection(_ section: BXFStaticTableViewInfoSection) -> UIView {
        return BXFStaticTableView.createSection(section)
    }
    
    static func createSection(_ section: BXFStaticTableViewInfoSection) -> UIView {
        let sectionView = UIView()
        
        sectionView.addSubview(section.header)
        sectionView.addSubview(section.footer)
        
        section.header.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }
        
        section.footer.snp.makeConstraints { (make) in
            make.top.equalTo(section.header.snp.bottom).offset(6)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        return sectionView
    }
    
    public func enableScroll(_ enable: Bool) {
        scrollView.isScrollEnabled = enable
    }
    
    public func addSection(_ section: BXFStaticTableViewSection) {
        addSection(createSection(section))
    }
    
    public func addSection(_ section: BXFStaticTableViewInfoSection) {
        addSection(createSection(section))
    }
    
    public func addSection(_ section: UIView) {
        stackView.addArrangedSubview(section)
    }
    
    public func insertSection(_ section: BXFStaticTableViewSection, at index: Int) {
        insertSection(createSection(section), at: index)
    }
    
    public func insertSection(_ section: UIView, at index: Int) {
        stackView.insertArrangedSubview(section, at: index)
    }
    
    public func addView(_ view: UIView) {
        stackView.addArrangedSubview(view)
    }
    
    public func removeAllViews() {
        stackView.arrangedSubviews.forEach { (subview) in
            subview.removeFromSuperview()
        }
    }
    
    func animateLayout() {
        UIView.animate(withDuration: BXFStaticTableViewAppearance.layoutAnimationDuration) {
            self.scrollView.layoutIfNeeded()
        }
    }
}
