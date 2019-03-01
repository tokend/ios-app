import UIKit

class ScrollableStackView: UIView {
    
    enum AnimatedTransition {
        //case fade
        case none
    }
    
    // MARK: - Public properties
    
    var stackViewsSpacing: CGFloat = 20.0 {
        didSet {
            self.updateArrangedViewsLayout()
        }
    }
    
    var fadeDuration: TimeInterval = 4
    
    // MARK: - Private properties
    
    private let scrollView: UIScrollView = UIScrollView()
    private let contentView: UIView = UIView()
    private var arrangedViews: [UIView] = []
    
    private var views: [UIView] {
        return self.arrangedViews
    }
    
    // MARK: -
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.customInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.customInit()
    }
    
    private func customInit() {
        self.setupView()
        self.setupScrollView()
        self.setupContentView()
        self.setupLayout()
        
        self.addKeyboardObserver()
    }
    
    // MARK: - Public
    
    func insert(views: [UIView], atIndex: Int = 0, transition: AnimatedTransition = .none) {
        switch transition {
            
            //case .fade:
            //    self.fade(removedViews: [], insertedViews: views, atIndex: atIndex)
            
        case .none:
            self.set(removedViews: [], insertedViews: views, atIndex: atIndex)
        }
    }
    
    func remove(views: [UIView], transition: AnimatedTransition = .none) {
        switch transition {
            
            //case .fade:
            //    self.fade(removedViews: views, insertedViews: [], atIndex: 0)
            
        case .none:
            self.set(removedViews: views, insertedViews: [], atIndex: 0)
        }
    }
    
    func set(views: [UIView], transition: AnimatedTransition = .none) {
        switch transition {
            
            //case .fade:
            //    self.fade(removedViews: self.views, insertedViews: views, atIndex: 0)
            
        case .none:
            self.set(removedViews: self.views, insertedViews: views, atIndex: 0)
        }
    }
    
    // MARK: - Private
    
    private func setupView() {
        self.backgroundColor = Theme.Colors.containerBackgroundColor
    }
    
    private func setupScrollView() {
        
    }
    
    private func setupContentView() {
        self.contentView.backgroundColor = UIColor.clear
    }
    
    private func setupLayout() {
        self.addSubview(self.scrollView)
        self.scrollView.addSubview(self.contentView)
        
        self.scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        self.contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.width.equalTo(self)
        }
    }
    
    private func updateArrangedViewsLayout() {
        var previousView: UIView?
        let count = self.arrangedViews.count
        for (index, view) in self.arrangedViews.enumerated() {
            view.snp.remakeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                if let prev = previousView {
                    make.top.equalTo(prev.snp.bottom).offset(self.stackViewsSpacing)
                } else {
                    make.top.equalToSuperview().offset(self.stackViewsSpacing)
                }
                if index == count - 1 {
                    make.bottom.equalToSuperview()
                }
            }
            previousView = view
        }
    }
    
    private func addKeyboardObserver() {
        let keyboardObserver = KeyboardObserver(self) { [weak self] (attributes) in
            self?.setBottomInsetWithKeyboardAttributes(attributes)
        }
        KeyboardController.shared.add(observer: keyboardObserver)
    }
    
    private func setBottomInsetWithKeyboardAttributes(
        _ attributes: KeyboardAttributes?
        ) {
        
        let keyboardHeight: CGFloat = attributes?.heightInContainerView(self, view: self.scrollView) ?? 0
        var bottomInset: CGFloat = keyboardHeight
        if attributes?.showingIn(view: self) != true {
            if #available(iOS 11, *) {
                bottomInset += self.safeAreaInsets.bottom
            } else {
                bottomInset += self.alignmentRectInsets.bottom
            }
        }
        
        self.scrollView.contentInset.bottom = bottomInset
        self.scrollView.scrollIndicatorInsets.bottom = bottomInset
        
        if let textview = UIResponder.currentFirst() as? UIView {
            self.scrollToView(textview)
        }
    }
    
    private func scrollToView(_ view: UIView) {
        let rect = self.scrollView.convert(view.bounds, from: view)
        self.scrollView.scrollRectToVisible(rect, animated: true)
    }
    
    // MARK: No transition
    
    private func set(removedViews: [UIView], insertedViews: [UIView], atIndex: Int) {
        removedViews.forEach { (view) in
            view.removeFromSuperview()
            self.arrangedViews.remove(object: view)
        }
        
        for viewIndex in 0 ..< insertedViews.count {
            let view = insertedViews[viewIndex]
            self.contentView.addSubview(view)
            self.arrangedViews.insert(view, at: atIndex + viewIndex)
        }
        
        self.updateArrangedViewsLayout()
    }
    
    // MARK: Fade
    
    //private func fade(removedViews: [UIView], insertedViews: [UIView], atIndex: Int) {
    //    let halfDuration = self.fadeDuration / 2.0
    //
    //    let fadeIn: () -> Void = {
    //        guard insertedViews.count > 0 else {
    //            removedViews.forEach({ (view) in
    //                view.alpha = 1.0
    //            })
    //            return
    //        }
    //
    //        for viewIndex in 0 ..< insertedViews.count {
    //            let view = insertedViews[viewIndex]
    //            view.alpha = 0.0
    //            self.contentView.addSubview(view)
    //            self.arrangedViews.insert(view, at: atIndex + viewIndex)
    //        }
    //
    //        UIView.animate(
    //            withDuration: halfDuration,
    //            delay: 0.0,
    //            options: [ .curveEaseOut ],
    //            animations: {
    //                insertedViews.forEach({ (view) in
    //                    view.alpha = 1.0
    //                })
    //                self.contentView.layoutIfNeeded()
    //        },
    //            completion: { _ in
    //                removedViews.forEach({ (view) in
    //                    view.alpha = 1.0
    //                })
    //        })
    //    }
    //
    //    let fadeOut: () -> Void = {
    //        guard removedViews.count > 0 else {
    //            fadeIn()
    //            return
    //        }
    //
    //        UIView.animate(
    //            withDuration: halfDuration,
    //            delay: 0.0,
    //            options: [ .curveEaseIn ],
    //            animations: {
    //                removedViews.forEach({ (view) in
    //                    view.alpha = 0.0
    //                })
    //        },
    //            completion: { _ in
    //                removedViews.forEach({ (view) in
    //                    view.removeFromSuperview()
    //                })
    //
    //                fadeIn()
    //        })
    //    }
    //
    //    fadeOut()
    //}
}
