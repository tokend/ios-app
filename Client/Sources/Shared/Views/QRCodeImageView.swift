import UIKit

class QRCodeImageView: UIImageView {

    // MARK: - Private properties

    private let qrCodeGenerator: QRCodeGenerator = .init()

    private var cancellable: QRCodeGenerator.Cancellable?

    // MARK: - Public properties

    public var qrValue: String? {
        didSet {
            guard oldValue != qrValue else { return }
            generateQrCode()
        }
    }

    public override var tintColor: UIColor! {
        didSet {
            guard oldValue != tintColor else { return }
            generateQrCode()
        }
    }

    public override var backgroundColor: UIColor? {
        didSet {
            guard oldValue != backgroundColor else { return }
            generateQrCode()
        }
    }
    
    override var bounds: CGRect {
        didSet {
            guard oldValue != bounds else { return }
            generateQrCode()
        }
    }
}

// MARK: - Private methods

private extension QRCodeImageView {

    func generateQrCode() {

        cancellable?.cancel()
        cancellable = nil

        image = nil

        if let value = qrValue {
            cancellable = qrCodeGenerator.generateQRCodeFromString(
                value,
                withTintColor: tintColor,
                backgroundColor: backgroundColor ?? .clear,
                size: .init(
                    width: min(bounds.width, bounds.height),
                    height: min(bounds.width, bounds.height)
                ),
                completion: { [weak self] (code) in
                    DispatchQueue.main.async { [weak self] in
                        self?.image = code
                    }
            })
        }
    }
}
