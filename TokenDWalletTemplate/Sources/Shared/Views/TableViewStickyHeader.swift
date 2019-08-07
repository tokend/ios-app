import UIKit

class TableViewStickyHeader: UIView {
    
    enum ChangeTextAnimationType {
        case animateDown
        case animateUp
        case withoutAnimation
    }
    
    // MARK: - Private properties
    
    private let headerVisualEffectView: UIVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    
    private let headerVisualEffectViewHeight: CGFloat = 24
    private let labelCornerRadius: CGFloat = 4
    private let sideMargin: CGFloat = 16
    
    private let appearAnimationDuration: TimeInterval = 0.4
    private let disappearAnimationDuration: TimeInterval = 0.2
    private let textChangeAnimationDuration: TimeInterval = 0.15
    private var frameChangeAnimationDuration: TimeInterval {
        return self.textChangeAnimationDuration
    }
    
    private var currentLabel: UILabel?
    
    private var hideHeaderTimer: DispatchWorkItem?
    private lazy var hideHeaderTimerBlock: () -> Void = {
        return { [weak self] in
            self?.hideHeader()
        }
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public
    
    func setHeaderPosition(_ y: CGFloat) {
        self.center.y = y
    }
    
    func hideHeader(animated: Bool = true) {
        self.makeHeader(visible: false, animated: animated)
    }
    
    func showHeader(animated: Bool = true) {
        self.startHideHeaderTimerWithDeadline()
        self.makeHeader(visible: true, animated: animated)
    }
    
    func startHideHeaderTimerWithDeadline(_ deadline: TimeInterval = 2) {
        self.hideHeaderTimer?.cancel()
        let timer = DispatchWorkItem(block: self.hideHeaderTimerBlock)
        self.hideHeaderTimer = timer
        DispatchQueue.main.asyncAfter(deadline: .now() + deadline, execute: timer)
    }
    
    func setText(
        _ text: String?,
        animation: ChangeTextAnimationType
        ) {
        
        let animated: Bool = {
            switch animation {
            case .animateDown:
                return true
            case .animateUp:
                return true
            case .withoutAnimation:
                return false
            }
        }()
        
        guard let text = text else {
            UIView.animate(withDuration: self.disappearAnimationDuration) {
                self.currentLabel?.text = nil
                self.headerVisualEffectView.snp.updateConstraints({ (make) in
                    make.width.equalTo(self.currentLabel?.frame.size.height ?? (2 * self.labelCornerRadius))
                })
                self.layoutIfNeeded()
            }
            self.hideHeader(animated: animated)
            return
        }
        
        let newLabel = self.createNewLabel()
        newLabel.text = text
        newLabel.sizeToFit()
        
        let newWidth = newLabel.frame.size.width + self.sideMargin * 2
        if (newWidth > self.headerVisualEffectView.frame.width) ||
            (newWidth < self.headerVisualEffectView.frame.width - sideMargin) {
            UIView.animate(withDuration: frameChangeAnimationDuration) {
                self.headerVisualEffectView.snp.updateConstraints({ (make) in
                    make.width.equalTo(newWidth)
                })
                self.layoutIfNeeded()
            }
        }
        
        self.addSubview(newLabel)
        let oldLabel = self.currentLabel
        
        self.currentLabel = newLabel
        newLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        let completion = {
            oldLabel?.removeFromSuperview()
        }
        
        let delta: CGFloat = {
            switch animation {
            case .animateDown:
                return self.headerVisualEffectView.frame.height
            case .animateUp:
                return -self.headerVisualEffectView.frame.height
            case .withoutAnimation:
                return 0
            }
        }()
        
        self.currentLabel?.alpha = 0
        self.currentLabel?.snp.updateConstraints({ (make) in
            make.centerY.equalToSuperview().inset(delta)
        })
        self.currentLabel?.superview?.layoutIfNeeded()
        
        UIView.animate(
            withDuration: animated ? textChangeAnimationDuration : 0,
            animations: {
                self.currentLabel?.snp.updateConstraints({ (make) in
                    make.centerY.equalToSuperview()
                })
                oldLabel?.snp.updateConstraints({ (make) in
                    make.centerY.equalToSuperview().inset(-delta)
                })
                self.currentLabel?.alpha = 1
                oldLabel?.alpha = 0
                self.layoutIfNeeded()
        }, completion: { (_) in
            completion()
        })
    }
    
    // MARK: - Private
    
    private func commonInit() {
        self.setupHeader()
        self.setupHeaderVisualEffectView()
        self.setupLayout()
        
        self.hideHeader(animated: false)
    }
    
    private func setupHeader() {
        self.backgroundColor = UIColor.clear
        self.isUserInteractionEnabled = false
    }
    
    private func setupHeaderVisualEffectView() {
        self.headerVisualEffectView.backgroundColor = Theme.Colors.stickyHeaderBackgroundColor
        self.headerVisualEffectView.layer.cornerRadius = self.labelCornerRadius
        self.headerVisualEffectView.clipsToBounds = true
    }
    
    private func setupLayout() {
        self.addSubview(self.headerVisualEffectView)
        self.headerVisualEffectView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(2 * self.labelCornerRadius)
            make.height.equalTo(self.headerVisualEffectViewHeight)
        }
    }
    
    private func makeHeader(
        visible: Bool,
        animated: Bool = true
        ) {
        
        if visible,
            self.currentLabel?.text?.isEmpty != false {
            self.makeHeader(visible: false, animated: animated)
            return
        }
        
        let animatedDuration: TimeInterval = visible ? self.appearAnimationDuration : self.disappearAnimationDuration
        let animationDuration: TimeInterval = animated ? animatedDuration : 0
        let alpha: CGFloat = visible ? 1 : 0
        UIView.animate(withDuration: animationDuration) {
            self.alpha = alpha
        }
    }
    
    private func createNewLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Theme.Fonts.smallTextFont
        label.textColor = Theme.Colors.stickyHeaderTitleColor
        label.backgroundColor = UIColor.clear
        label.textAlignment = .center
        return label
    }
}
