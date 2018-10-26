import UIKit

class BXFStaticTableViewSectionHeaderFooterView: UIView {
    
    enum HeaderFooterType {
        case header
        case footer
    }
    
    private let label: BXFGroupedHeaderFooterLabel = BXFGroupedHeaderFooterLabel.headerFooterLabel()
    
    private var showText: Bool = true
    
    private var text: String?
    private var type: HeaderFooterType = .header
    
    private let errorPrefix: String = "\n"
    private var currentError: String = ""
    private var isShowingError: Bool = false
    
    private let infoPrefix: String = "\n"
    private var currentInfo: String = ""
    private var isShowingInfo: Bool = false
    
    static func instantiate(
        with type: HeaderFooterType,
        text: String?) -> BXFStaticTableViewSectionHeaderFooterView {
        
        let view = BXFStaticTableViewSectionHeaderFooterView()
        
        view.type = type
        
        view.label.textColor = BXFStaticTableViewAppearance.Section.HeaderFooter.color
        view.label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        view.addSubview(view.label)
        view.label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        switch type {
            
        case .footer:
            view.label.bottomTextInset = 0
            
        case .header:
            view.label.topTextInset = 0
        }
        
        view.setText(text)
        
        return view
    }
    
    func showError(_ error: String, withTitle: Bool) {
        showText = withTitle
        showError(error)
    }
    
    override func showError(_ error: String) {
        currentError = prefix(errorPrefix, for: error) + error
        isShowingError = true
        setupText()
        label.textColor = BXFStaticTableViewAppearance.Section.HeaderFooter.errorColor
    }
    
    override func hideError() {
        isShowingError = false
        showText = true
        setupText()
        label.textColor = BXFStaticTableViewAppearance.Section.HeaderFooter.color
    }
    
    func showInfo(_ info: String) {
        currentInfo = prefix(infoPrefix, for: info) + info
        isShowingInfo = true
        setupText()
    }
    
    func hideInfo() {
        isShowingInfo = false
        setupText()
    }
    
    func setTopInset(_ inset: CGFloat) {
        label.topTextInset = inset
    }
    
    func setBottomInset(_ inset: CGFloat) {
        label.bottomTextInset = inset
    }
    
    func setText(_ text: String?) {
        switch type {
        case .footer:
            self.text = text
        case .header:
            self.text = text?.uppercased()
        }
        setupText()
    }
    
    private func setupText() {
        var justText = ""
        
        if showText {
            justText.append(text ?? "")
        }
        
        if isShowingInfo {
            justText.append(currentInfo)
        }
        if isShowingError {
            justText.append(currentError)
        }
        label.text = justText
    }
    
    private func prefix(_ prefix: String, for textAfterPrefix: String) -> String {
        return ((text ?? "").isEmpty || textAfterPrefix.isEmpty) ? "" : prefix
    }
    
    private func remove(_ textToRemove: String, from text: String) -> String {
        return text.replacingOccurrences(of: textToRemove, with: "")
    }
}
