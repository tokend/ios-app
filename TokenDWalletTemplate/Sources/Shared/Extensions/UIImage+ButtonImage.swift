import UIKit

extension UIImage {
    static func resizableImageWithColor(_ color: UIColor) -> UIImage? {
        let size = CGSize(width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        color.setFill()
        context.fill(CGRect(origin: CGPoint.zero, size: size))
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        
        let resizableImage = image.resizableImage(withCapInsets: UIEdgeInsets.zero, resizingMode: .stretch)
        return resizableImage
    }
}
