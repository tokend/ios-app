import UIKit

extension UITextField {

    func setText(
        _ text: String
    ) {

        let oldLocation = self.selectedTextRange?.start
        let oldTextSize = self.text?.count ?? 0
        let newTextSize = text.count
        
        self.text = text
        
        if let location = oldLocation,
            let newLocation = position(from: location, offset: newTextSize - oldTextSize) {
            selectedTextRange = textRange(from: newLocation, to: newLocation)
        }
    }
}
