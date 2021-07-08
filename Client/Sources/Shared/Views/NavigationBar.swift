//import UIKit
//import RxSwift
//
//class NavigationBar: UIView {
//
//    struct BarButtonItem {
//
//        enum Content {
//            case title(String)
//            case icon(UIImage)
//        }
//
//        let content: Content
//        let action: (() -> Void)?
//
//        init(
//            content: Content,
//            action: (() -> Void)?
//        ) {
//            self.content = content
//            self.action = action
//        }
//    }
//
//    enum Style {
//
//        case darkContent
//        case lightContent
//    }
//
//    // MARK: - Private properties
//
//    private let titleContainerView: UIStackView = .init()
//
//    private let titleLabel: UILabel = .init()
//    private let titleDownArrowImageView: UIImageView = .init()
//    private let titleImageView: UIImageView = .init()
//    private let titleView: UIView = .init()
//
//    private let leftBarButtonsContainer: UIStackView = .init()
//    private let rightBarButtonsContainer: UIStackView = .init()
//
//    private let disposeBag: DisposeBag = .init()
//
//    private var commonBackgroundColor: UIColor { .clear }
//    private var isTitleContainerVisible: Bool { title != nil || titleImage != nil }
//    private var barButtonSideInset: CGFloat { 14.0 }
//    private var largeTitleSideInset: CGFloat { 24.0 }
//    private var barButtonItemHeight: CGFloat { 44.0 }
//    private var largeTitleButtonInset: CGFloat { 16.0 }
//    private var titleFont: UIFont { Theme.Fonts.semiboldFont.withSize(16.0) }
//    private var largeTitleFont: UIFont { Theme.Fonts.bold.withSize(20.0) }
//
//    // MARK: - Public properties
//
//    public var prefersLargeTitles: Bool = false {
//        didSet {
//            renderPrefersLargeTitlesDidChange()
//            invalidateIntrinsicContentSize()
//        }
//    }
//
//    public var style: Style = .darkContent {
//        didSet {
//            renderStyleDidChange()
//        }
//    }
//
//    public var titleTapAction: (() -> Void)?
//    public var isTitleActionAvailable: Bool = false {
//        didSet {
//            renderTitleActionAvailable()
//        }
//    }
//
//    public var title: String? {
//        get { titleLabel.text }
//        set {
//            titleLabel.text = newValue
//            renderTitleDidChange()
//            invalidateIntrinsicContentSize()
//        }
//    }
//
//    public var titleImage: UIImage? {
//        get { titleImageView.image }
//        set {
//            titleImageView.image = newValue
//            renderTitleDidChange()
//            invalidateIntrinsicContentSize()
//        }
//    }
//
//    public var titleIndicatorView: UIView? {
//        didSet {
//            oldValue?.removeFromSuperview()
//
//            renderTitleIndicatorView()
//        }
//    }
//
//    // MARK: - Overridden
//
//    override var intrinsicContentSize: CGSize {
//        let barButtonsHeight: CGFloat = barButtonItemHeight
//
//        var height: CGFloat
//
//        if prefersLargeTitles {
//            height = barButtonsHeight
//
//            let availableWidth: CGFloat = bounds.width - 2 * barButtonSideInset
//            if isTitleContainerVisible {
//                height += largeTitleButtonInset
//                    + (title?.height(
//                        constraintedWidth: availableWidth,
//                        font: largeTitleFont) ?? 0)
//            }
//        } else {
//
//            let titleHeight: CGFloat = title?.height(
//                constraintedWidth: .greatestFiniteMagnitude,
//                font: titleFont) ?? (titleImage == nil ? 0.0 : 26.0)
//
//            var titlesHeight: CGFloat = 0
//            if isTitleContainerVisible {
//                titlesHeight += (barButtonsHeight - titleHeight) / 2.0 + titleHeight
//            }
//
//            height = max(barButtonsHeight, titlesHeight)
//        }
//
//        return .init(
//            width: UIView.noIntrinsicMetric,
//            height: height
//        )
//    }
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//
//        commonInit()
//    }
//
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//
//        commonInit()
//    }
//}
//
//// MARK: - Public methods
//
//extension NavigationBar {
//    func setLeftBarButtonItems(_ items: [BarButtonItem]) {
//        let buttons = items.map { self.makeBarButton(with: $0) }
//        leftBarButtonsContainer.removeArrangedSubviews()
//        buttons.forEach { self.leftBarButtonsContainer.addArrangedSubview($0) }
//    }
//
//    func setRightBarButtonItems(_ items: [BarButtonItem]) {
//        let buttons = items.map { self.makeBarButton(with: $0) }
//        rightBarButtonsContainer.removeArrangedSubviews()
//        buttons.reversed().forEach { self.rightBarButtonsContainer.addArrangedSubview($0) }
//    }
//}
//
//// MARK: - Private methods
//
//private extension NavigationBar {
//    func commonInit() {
//        setupView()
//        setupTitleContainerView()
//        setupTitleLabel()
//        setupTitleImageView()
//        setupTitleDownArrowImageView()
//        setupSubtitleLabel()
//        setupLeftBarButtonsContainer()
//        setupRightBarButtonsContainer()
//        setupTitleIndicatorView()
//        setupLayout()
//
//        renderTitleActionAvailable()
//    }
//
//    func setupView() {
//        backgroundColor = commonBackgroundColor
//
//        let tapGesture: UITapGestureRecognizer = .init()
//        tapGesture.cancelsTouchesInView = false
//        tapGesture.addTarget(
//            self,
//            action: #selector(tapGestureAction)
//        )
//        addGestureRecognizer(tapGesture)
//    }
//
//    @objc func tapGestureAction() {
//        titleTapAction?()
//    }
//
//    func setupTitleContainerView() {
//        titleContainerView.spacing = 12.0
//        titleContainerView.alignment = .center
//        titleContainerView.axis = .horizontal
//        titleContainerView.distribution = .fill
//        titleContainerView.backgroundColor = commonBackgroundColor
//    }
//
//    func setupTitleLabel() {
//        makeTitleLabel(titleLabel)
//        titleLabel.backgroundColor = commonBackgroundColor
//    }
//
//    func setupTitleImageView() {
//        titleImageView.contentMode = .scaleAspectFit
//    }
//
//    func setupTitleDownArrowImageView() {
//        titleDownArrowImageView.tintColor = Theme.Colors.dark
//        titleDownArrowImageView.image = Assets.arrowDown.image
//    }
//
//    func setupSubtitleLabel() {
//        makeSubtitleLabel(subtitleLabel)
//        subtitleLabel.backgroundColor = commonBackgroundColor
//    }
//
//    func setupLeftBarButtonsContainer() {
//        leftBarButtonsContainer.alignment = .fill
//        leftBarButtonsContainer.axis = .horizontal
//        leftBarButtonsContainer.distribution = .fill
//        leftBarButtonsContainer.spacing = barButtonSideInset
//    }
//
//    func setupRightBarButtonsContainer() {
//        rightBarButtonsContainer.alignment = .fill
//        rightBarButtonsContainer.axis = .horizontal
//        rightBarButtonsContainer.distribution = .fill
//        rightBarButtonsContainer.spacing = barButtonSideInset
//    }
//
//    func setupTitleIndicatorView() {
//        titleIndicatorView?.backgroundColor = commonBackgroundColor
//    }
//
//    func setupLayout() {
//        addSubview(leftBarButtonsContainer)
//        addSubview(rightBarButtonsContainer)
//        addSubview(titleContainerView)
//        titleContainerView.addArrangedSubview(titleLabel)
//        titleContainerView.addArrangedSubview(titleDownArrowImageView)
//        addSubview(subtitleLabel)
//
//        leftBarButtonsContainer.setContentHuggingPriority(.required, for: .horizontal)
//        leftBarButtonsContainer.snp.makeConstraints { (make) in
//            make.left.equalToSuperview().inset(barButtonSideInset)
//            make.top.equalTo(safeArea.top)
//            make.bottom.lessThanOrEqualToSuperview()
//            make.height.equalTo(barButtonItemHeight)
//        }
//
//        rightBarButtonsContainer.setContentHuggingPriority(.required, for: .horizontal)
//        rightBarButtonsContainer.snp.makeConstraints { (make) in
//            make.right.equalToSuperview().inset(barButtonSideInset)
//            make.top.equalTo(safeArea.top)
//            make.bottom.lessThanOrEqualToSuperview()
//            make.height.equalTo(barButtonItemHeight)
//        }
//
//        titleDownArrowImageView.snp.makeConstraints { (make) in
//            make.width.equalTo(8.0)
//            make.height.equalTo(4.0)
//        }
//
//        remakeTitleSubtitleConstraints()
//    }
//
//    func remakeTitleSubtitleConstraints() {
//        if prefersLargeTitles {
//            titleContainerView.snp.remakeConstraints { (make) in
//                if isTitleContainerVisible {
//                    make.top.equalTo(leftBarButtonsContainer.snp.bottom).offset(largeTitleButtonInset)
//                    make.left.right.equalToSuperview().inset(largeTitleSideInset)
//                    if !isSubtitleLabelVisible {
//                        make.bottom.equalToSuperview()
//                    }
//                }
//            }
//
//            subtitleLabel.snp.remakeConstraints { (make) in
//                if isSubtitleLabelVisible {
//                    make.left.right.equalToSuperview().inset(largeTitleSideInset)
//                    if isTitleContainerVisible {
//                        make.top.equalTo(titleLabel.snp.bottom).offset(largeSubtitleTitleInset)
//                    } else {
//                        make.top.equalTo(leftBarButtonsContainer.snp.bottom).offset(largeSubtitleButtonInset)
//                    }
//                    make.bottom.equalToSuperview()
//                }
//            }
//        } else {
//            titleContainerView.snp.remakeConstraints { (make) in
//                if isTitleContainerVisible {
//                    make.left.greaterThanOrEqualTo(leftBarButtonsContainer.snp.right).offset(barButtonSideInset)
//                    make.right.lessThanOrEqualTo(rightBarButtonsContainer.snp.left).offset(-barButtonSideInset)
//                    make.centerX.equalToSuperview()
//                    make.top.greaterThanOrEqualTo(safeArea.top)
//                    make.centerY.equalTo(leftBarButtonsContainer)
//                    if !isSubtitleLabelVisible {
//                        make.bottom.lessThanOrEqualToSuperview()
//                    }
//                }
//            }
//
//            subtitleLabel.snp.remakeConstraints { (make) in
//                if isSubtitleLabelVisible {
//                    make.left.greaterThanOrEqualTo(leftBarButtonsContainer.snp.right).offset(barButtonSideInset)
//                    make.right.lessThanOrEqualTo(rightBarButtonsContainer.snp.left).offset(-barButtonSideInset)
//                    make.centerX.equalToSuperview()
//                    if isTitleContainerVisible {
//                        make.top.equalTo(titleLabel.snp.bottom).offset(subtitleTitleInset)
//                    } else {
//                        make.centerY.equalTo(leftBarButtonsContainer)
//                        make.top.greaterThanOrEqualTo(safeArea.top)
//                    }
//                    make.bottom.lessThanOrEqualToSuperview()
//                }
//            }
//        }
//
//        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
//        subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
//    }
//
//    func renderPrefersLargeTitlesDidChange() {
//        if prefersLargeTitles {
//            makeLargeTitleLabel(titleLabel)
//            makeLargeSubtitleLabel(subtitleLabel)
//        } else {
//            makeTitleLabel(titleLabel)
//            makeSubtitleLabel(subtitleLabel)
//        }
//
//        renderTitleDidChange()
//        renderSubtitleDidChange()
//
//        remakeTitleSubtitleConstraints()
//    }
//
//    func renderStyleDidChange() {
//        if prefersLargeTitles {
//            makeLargeTitleLabel(titleLabel)
//            makeLargeSubtitleLabel(subtitleLabel)
//        } else {
//            makeTitleLabel(titleLabel)
//            makeSubtitleLabel(subtitleLabel)
//        }
//
//        // FIXME: Render bar buttons style changes
//    }
//
//    func renderTitleDidChange() {
//        if let title = title {
//
//            hideIfNeeded(false, label: titleLabel)
//
//            titleImageView.removeFromSuperview()
//            titleImageView.image = nil
//            titleContainerView.addArrangedSubview(titleLabel)
//
//            let attributes: [NSAttributedString.Key: Any]
//            if prefersLargeTitles {
//                let paragraphStyle = NSMutableParagraphStyle()
//                paragraphStyle.lineSpacing = 0.8
//                paragraphStyle.lineBreakMode = .byTruncatingTail
//
//                attributes = [
//                    NSAttributedString.Key.kern: -0.64,
//                    NSAttributedString.Key.paragraphStyle: paragraphStyle
//                ]
//            } else {
//                let paragraphStyle = NSMutableParagraphStyle()
//                paragraphStyle.lineSpacing = 0.95
//
//                attributes = [
//                    NSAttributedString.Key.paragraphStyle: paragraphStyle
//                ]
//            }
//
//            titleLabel.attributedText = .init(
//                string: title,
//                attributes: attributes
//            )
//        } else if let titleImage = titleImage {
//            hideIfNeeded(true, label: titleLabel)
//
//            titleLabel.removeFromSuperview()
//            titleLabel.text = nil
//            titleContainerView.addArrangedSubview(titleImageView)
//
//            titleImageView.image = titleImage
//        } else {
//            hideIfNeeded(true, label: titleLabel)
//            titleLabel.text = nil
//            titleImageView.image = nil
//        }
//    }
//
//    func renderSubtitleDidChange() {
//        guard let subtitle = subtitle
//            else {
//                hideIfNeeded(true, label: subtitleLabel)
//                return
//        }
//
//        hideIfNeeded(false, label: subtitleLabel)
//        let paragraphStyle = NSMutableParagraphStyle()
//        paragraphStyle.lineSpacing = 0.95
//        paragraphStyle.lineBreakMode = .byTruncatingMiddle
//
//        let attributes: [NSAttributedString.Key: Any] = [
//            NSAttributedString.Key.paragraphStyle: paragraphStyle
//        ]
//
//        subtitleLabel.attributedText = .init(
//            string: subtitle,
//            attributes: attributes
//        )
//    }
//
//    func renderTitleIndicatorView() {
//
//        if let titleIndicatorView = titleIndicatorView {
//            titleContainerView.addArrangedSubview(titleIndicatorView)
//        }
//    }
//
//    func hideIfNeeded(_ hide: Bool, label: UILabel) {
//        guard label.isHidden != hide else { return }
//        label.isHidden = hide
//        remakeTitleSubtitleConstraints()
//    }
//
//    func makeTitleLabel(_ label: UILabel) {
//        label.textAlignment = .center
//        label.numberOfLines = 1
//        label.lineBreakMode = .byWordWrapping
//        label.font = titleFont
//        switch style {
//        case .darkContent:
//            label.textColor = Theme.Colors.navigationBarDarkTitleColorOnMainBackgroundColor
//        case .lightContent:
//            label.textColor = Theme.Colors.navigationBarLightTitleColorOnMainBackgroundColor
//        }
//    }
//
//    func makeSubtitleLabel(_ label: UILabel) {
//        label.textAlignment = .center
//        label.numberOfLines = 1
//        label.lineBreakMode = .byTruncatingMiddle
//        label.font = subtitleFont
//        switch style {
//        case .darkContent:
//            label.textColor = Theme.Colors.navigationBarDarkSubtitleColorOnMainBackgroundColor
//        case .lightContent:
//            label.textColor = Theme.Colors.navigationBarLightSubtitleColorOnMainBackgroundColor
//        }
//    }
//
//    func makeLargeTitleLabel(_ label: UILabel) {
//        label.textAlignment = .left
//        label.numberOfLines = 0
//        label.lineBreakMode = .byWordWrapping
//        label.font = largeTitleFont
//
//        switch style {
//        case .darkContent:
//            label.textColor = Theme.Colors.navigationBarDarkLargeTitleColorOnMainBackgroundColor
//        case .lightContent:
//            label.textColor = Theme.Colors.navigationBarLightLargeTitleColorOnMainBackgroundColor
//        }
//    }
//
//    func makeLargeSubtitleLabel(_ label: UILabel) {
//        label.textAlignment = .left
//        label.numberOfLines = 0
//        label.lineBreakMode = .byWordWrapping
//        label.font = largeSubtitleFont
//        switch style {
//        case .darkContent:
//            label.textColor = Theme.Colors.navigationBarDarkLargeSubtitleColorOnMainBackgroundColor
//        case .lightContent:
//            label.textColor = Theme.Colors.navigationBarLightLargeSubtitleColorOnMainBackgroundColor
//        }
//    }
//
//    func makeBarButton(with item: BarButtonItem) -> UIButton {
//        let barButton: UIButton = .init(type: .system)
//        let notificationIndicator: UIView = .init()
//        let notificationIndicatorSize: CGSize = .init(width: 8.0, height: 8.0)
//
//        barButton.addSubview(notificationIndicator)
//        notificationIndicator.layer.cornerRadius = notificationIndicatorSize.width / 2
//        notificationIndicator.backgroundColor = Theme.Colors.orange
//        notificationIndicator.snp.makeConstraints { (make) in
//            make.size.equalTo(notificationIndicatorSize)
//            make.top.trailing.equalToSuperview().inset(6.0)
//        }
//
//        notificationIndicator.isHidden = !item.notificationIndicator
//
//        barButton.backgroundColor = commonBackgroundColor
//        switch style {
//        case .darkContent:
//            barButton.tintColor = Theme.Colors.navigationBarDarkButtonTintColorOnMainBackgroundColor
//        case .lightContent:
//            barButton.tintColor = Theme.Colors.navigationBarLightButtonTintColorOnMainBackgroundColor
//        }
//
//        switch item.content {
//        case let .icon(icon):
//            barButton.setImage(icon, for: .normal)
//        case let .title(title):
//            barButton.setTitle(title, for: .normal)
//
//            switch style {
//            case .darkContent:
//                barButton.setTitleColor(Theme.Colors.navigationBarDarkTitleButtonTintColorOnMainBackgroundColor, for: .normal)
//            case .lightContent:
//                barButton.setTitleColor(Theme.Colors.navigationBarLightTitleButtonTintColorOnMainBackgroundColor, for: .normal)
//            }
//        }
//        barButton.contentMode = .scaleAspectFit
//        barButton.contentEdgeInsets = .init(top: 12.0, left: 12.0, bottom: 12.0, right: 12.0)
//        barButton.setContentCompressionResistancePriority(.required, for: .horizontal)
//        barButton.setContentCompressionResistancePriority(.required, for: .vertical)
//
//        barButton
//            .rx
//            .tap
//            .asDriver()
//            .drive(onNext: { (_) in
//                item.action?()
//            })
//            .disposed(by: disposeBag)
//
//        return barButton
//    }
//
//    func renderTitleActionAvailable() {
//        titleDownArrowImageView.isHidden = !isTitleActionAvailable
//    }
//}
//
