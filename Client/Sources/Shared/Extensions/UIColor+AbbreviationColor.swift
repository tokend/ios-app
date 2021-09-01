import UIKit

extension UIColor {
    
    
    class func abbreviationColor() -> UIColor {
        
        let colors: [UIColor] = [.systemRed, .systemGreen, .systemOrange, .systemBlue, .systemPink]
        
        guard let color = colors.randomElement()
        else {
            return .systemGray
        }
        return color.withAlphaComponent(0.7)
    }
}
