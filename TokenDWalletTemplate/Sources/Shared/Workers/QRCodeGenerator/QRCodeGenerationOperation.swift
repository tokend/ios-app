import UIKit

class QRCodeGenerationOperation: Operation {
    
    private let string: String
    private let size: CGSize
    private let correctionLevel: CorrectionLevel
    private let backgroundColor: UIColor
    private let tintColor: UIColor
    private let callback: (UIImage?) -> Void
    
    override func cancel() {
        super.cancel()
        
        if self.isCancelled && !self.isFinished {
            self.callback(nil)
        }
    }
    
    init(
        source: String,
        size: CGSize,
        tintColor: UIColor,
        backgroundColor: UIColor,
        callback: @escaping (UIImage?) -> Void
        ) {
        
        self.string = source
        self.size = size
        self.correctionLevel = .H
        self.backgroundColor = backgroundColor
        self.tintColor = tintColor
        self.callback = callback
    }
    
    override func main() {
        
        let image = self.generateQR()
        
        guard !self.isCancelled else {
            return
        }
        
        callback(image)
    }
    
    private func generateQR() -> UIImage? {
        
        if self.isCancelled { return nil }
        
        guard
            let filter = CIFilter(name: "CIQRCodeGenerator"),
            let colorFilter = CIFilter(name: "CIFalseColor")
            else {
                return nil
        }
        
        let scaleMultiplier: CGFloat = UIScreen.main.scale
        
        let data = self.string.data(using: String.Encoding.isoLatin1, allowLossyConversion: false)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(self.correctionLevel.rawValue, forKey: "inputCorrectionLevel")
        
        colorFilter.setDefaults()
        colorFilter.setValue(filter.outputImage!, forKey: "inputImage")
        colorFilter.setValue(CIColor(color: self.tintColor), forKey: "inputColor0")
        colorFilter.setValue(CIColor(color: self.backgroundColor), forKey: "inputColor1")
        
        if self.isCancelled { return nil }
        
        guard
            let qrColoredImage = colorFilter.outputImage
            else {
                return nil
        }
        
        let scaleX = scaleMultiplier * self.size.width / qrColoredImage.extent.width
        let scaleY = scaleMultiplier * self.size.height / qrColoredImage.extent.height
        let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        
        if self.isCancelled { return nil }
        
        let qrcodeImageColored = qrColoredImage.transformed(by: transform)
        let ciContext = CIContext()
        
        if self.isCancelled { return nil }
        
        let optionalCgImage = ciContext.createCGImage(
            qrcodeImageColored,
            from: qrcodeImageColored.extent
        )
        
        guard
            let cgImage = optionalCgImage
            else {
                return nil
        }
        
        if self.isCancelled { return nil }
        
        let image = UIImage(cgImage: cgImage)
        
        if self.isCancelled { return nil }
        
        return image
    }
}

extension QRCodeGenerationOperation {
    // swiftlint:disable identifier_name
    enum CorrectionLevel: String {
        
        /// 7% error resilience
        case L
        
        /// 15% error resilience
        case M
        
        /// 25% error resilience
        case Q
        
        /// 30% error resilience
        case H
    }
    // swiftlint:enable identifier_name
}
