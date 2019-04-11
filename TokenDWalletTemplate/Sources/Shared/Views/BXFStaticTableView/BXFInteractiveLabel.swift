import UIKit

class BXFInteractiveLabel: BXFLabelWithInsets {
    
    struct Action {
        var title: String = ""
        var action: (() -> Void)?
        fileprivate var selector: Selector?
        
        fileprivate init() { }
    }
    
    // MARK: - Private properties
    
    private var actions: [Action] {
        return [self.copyAction, self.shareAction]
    }
    
    // MARK: - Public properties
    
    public lazy var copyAction: Action = {
        var action = Action()
        action.selector = #selector(self.onCopyAction)
        return action
    }()
    public lazy var shareAction: Action = {
        var action = Action()
        action.selector = #selector(self.onShareAction)
        return action
    }()
    
    // MARK: - Overridden methods
    
    override public var canBecomeFirstResponder: Bool {
        return !self.actions.isEmpty
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.commonInit()
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return self.actions.contains(where: { (menuAction) -> Bool in
            return menuAction.selector == action
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Private
    
    @objc private func onCopyAction() {
        self.copyAction.action?()
    }
    
    @objc private func onShareAction() {
        self.shareAction.action?()
    }
    
    private func commonInit() {
        self.highlightedTextColor = Theme.Colors.mainColor
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(UILongPressGestureRecognizer(
            target: self,
            action: #selector(self.showMenu(sender:))
        ))
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.willShowMenu),
            name: UIMenuController.willShowMenuNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.willHideMenu),
            name: UIMenuController.willHideMenuNotification,
            object: nil
        )
    }
    
    @objc private func showMenu(sender: Any?) {
        let availableActions = self.actions.filter { (action) -> Bool in
            return action.action != nil && action.selector != nil
        }
        
        guard !availableActions.isEmpty else { return }
        
        let menu = UIMenuController.shared
        guard !menu.isMenuVisible
            && self.becomeFirstResponder()
            else {
                return
        }
        
        menu.menuItems = availableActions.compactMap({ (action) -> UIMenuItem? in
            guard let selector = action.selector
                else {
                    return nil
            }
            return UIMenuItem(title: action.title, action: selector)
        })
        
        menu.setTargetRect(bounds, in: self)
        menu.setMenuVisible(true, animated: true)
    }
    
    @objc private func willShowMenu() {
        self.isHighlighted = true
    }
    
    @objc private func willHideMenu() {
        self.isHighlighted = false
    }
}
