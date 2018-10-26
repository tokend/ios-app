import UIKit

class BXFStaticTableViewSectionCell: UIView {
    
    private(set) var contentView: UIView!
    
    static func instantiate(with contentView: UIView, border withBorder: Bool) -> BXFStaticTableViewSectionCell {
        let view = BXFStaticTableViewSectionCell()
        view.backgroundColor = BXFStaticTableViewAppearance.Section.Border.color
        
        view.contentView = contentView
        view.addSubview(contentView)
        let borderHeight: CGFloat = withBorder ? BXFStaticTableViewAppearance.Section.Border.height : 0
        contentView.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().inset(borderHeight)
            make.top.equalToSuperview().inset(borderHeight)
            make.trailing.equalToSuperview()
            make.leading.equalToSuperview()
        }
        
        return view
    }
    
    override func showError(_ error: String) {
        contentView.showError(error)
    }
    
    override func hideError() {
        contentView.hideError()
    }
    
    @discardableResult
    override func becomeFirstResponder() -> Bool {
        return contentView.becomeFirstResponder()
    }
}

protocol ErrorShowingAbilityView {
    func showError(_ error: String)
    func hideError()
}

extension UIView: ErrorShowingAbilityView {
    @objc func showError(_ error: String) { }
    @objc func hideError() { }
}
