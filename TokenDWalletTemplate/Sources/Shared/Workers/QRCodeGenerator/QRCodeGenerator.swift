import UIKit
    
class QRCodeGenerator {
    
    typealias QRCode = UIImage

    private let operationQueue: OperationQueue = OperationQueue()
    private let dispatchQueue: DispatchQueue = DispatchQueue(
        label: NSStringFromClass(QRCodeGenerator.self),
        qos: .userInteractive,
        attributes: .concurrent
    )

    init() {
        self.operationQueue.maxConcurrentOperationCount = 1
        self.operationQueue.underlyingQueue = self.dispatchQueue
    }

    func generateQRCodeFromString(
        _ string: String,
        withTintColor tintColor: UIColor,
        backgroundColor: UIColor,
        size: CGSize,
        completion: @escaping (QRCode?) -> Void
        ) {

        self.operationQueue.cancelAllOperations()
        let operation = QRCodeGenerationOperation(
            source: string,
            size: size,
            tintColor: tintColor,
            backgroundColor: backgroundColor,
            callback: completion
        )
        self.operationQueue.addOperation(operation)
    }
}
