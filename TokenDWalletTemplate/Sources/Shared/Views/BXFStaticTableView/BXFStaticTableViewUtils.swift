import UIKit

enum BXFStaticTableViewAppearance {
    
    static var backgroundColor: UIColor = UIColor.black
    static var space: CGFloat = 24
    static var layoutAnimationDuration: TimeInterval = 0.2
    
    enum Section {
        enum Border {
            static var color: UIColor = UIColor.black
            static var height: CGFloat = 1 / UIScreen.main.scale
        }
        
        enum HeaderFooter {
            static var color: UIColor = UIColor.black
            static var errorColor: UIColor = UIColor.black
        }
    }
}

@objc protocol BXFTextfieldValidator: class {
    
    var editingChangedHandler: () -> Void { get set }
    var errorHandler: (String) -> Void { get set }
    var clearError: () -> Void { get set }
    
    @objc optional func getValue(fromText text: String) -> String
    func validate(text: String) -> Bool
    func validate(text: String, withError: Bool) -> Bool
    func validateAndShowError(for text: String) -> Bool
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
        ) -> Bool
    func editingChanged(sender: UITextField)
}
