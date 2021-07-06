import UIKit
    
class QRCodeGenerator {

    class Cancellable {

        private let operation: Operation

        init(
            operation: Operation
        ) {

            self.operation = operation
        }

        func cancel() {
            operation.cancel()
        }
    }
    
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
        ) -> Cancellable {

        let operation = QRCodeGenerationOperation(
            source: string,
            size: size,
            tintColor: tintColor,
            backgroundColor: backgroundColor,
            callback: completion
        )
        self.operationQueue.addOperation(operation)

        return .init(
            operation: operation
        )
    }
}
