import UIKit

extension UIView {

    func asImage() -> UIImage? {

        layoutIfNeeded()
        let format: UIGraphicsImageRendererFormat = .init()
        format.opaque = false

        let renderer: UIGraphicsImageRenderer = .init(size: intrinsicContentSize, format: format)
        return renderer.image { (context) in
            self.layer.render(in: context.cgContext)
        }

//        layoutIfNeeded()
//        UIGraphicsBeginImageContextWithOptions(intrinsicContentSize, false, 0)
//
//        guard let context = UIGraphicsGetCurrentContext()
//            else {
//                return nil
//        }
//
//        context.saveGState()
//        layer.render(in: context)
//        context.restoreGState()
//
//        guard let snapshotImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
//            else {
//                return nil
//        }
//        UIGraphicsEndImageContext()
//
//        return snapshotImage.withRenderingMode(.alwaysOriginal)

//        guard let cgImage = snapshotImage.cgImage
//            else {
//                return nil
//        }
//
//        return .init(cgImage: cgImage)
    }
}
