import UIKit
import ContactsUI

class ContactEmailPickerHandler: NSObject {
    
    let onCanceled: (() -> Void)?
    let onSelected: ((_ emails: [String]) -> Void)?
    
    // MARK: -
    
    init(
        onCanceled: (() -> Void)?,
        onSelected: ((_ email: [String]) -> Void)?
        ) {
        
        self.onCanceled = onCanceled
        self.onSelected = onSelected
    }
    
    // MARK: - Public
    
    func getPredicate() -> NSPredicate? {
        return NSPredicate(format: "emailAddresses.@count > 0")
    }
}

extension ContactEmailPickerHandler: CNContactPickerDelegate {
    
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        self.onCanceled?()
    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        let emails: [String] = contact.emailAddresses.map({ (value) in
            return value.value as String
        })
        
        self.onSelected?(emails)
    }
}
