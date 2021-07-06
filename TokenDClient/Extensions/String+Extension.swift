import UIKit
import Foundation

extension String {
    
    static func singleLineHeight(
        font: UIFont,
        attributes: [NSAttributedString.Key: Any] = [:]
    ) -> CGFloat {
        
        font.lineHeight.rounded()
    }
    
    func height(
        constraintedWidth width: CGFloat,
        font: UIFont,
        attributes: [NSAttributedString.Key: Any] = [:]
    ) -> CGFloat {
        
        var resultingAttributes: [NSAttributedString.Key: Any] = attributes
        resultingAttributes[.font] = font
        let boundingRect = NSString(string: self).boundingRect(
            with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin],
            attributes: resultingAttributes,
            context: NSStringDrawingContext())
        return ceil(boundingRect.size.height)
    }
    
    func width(
        constraintedHeight height: CGFloat,
        font: UIFont,
        attributes: [NSAttributedString.Key: Any] = [:]
    ) -> CGFloat {
        
        var resultingAttributes: [NSAttributedString.Key: Any] = attributes
        resultingAttributes[.font] = font
        let boundingRect = NSString(string: self).boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: height),
            options: [.usesLineFragmentOrigin],
            attributes: resultingAttributes,
            context: NSStringDrawingContext())
        return ceil(boundingRect.size.width)
    }

    func size(with font: UIFont) -> CGSize {
        return NSString(string: self).size(withAttributes: [.font: font])
    }

    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }

    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }

    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }

    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex..<endIndex])
    }
}
