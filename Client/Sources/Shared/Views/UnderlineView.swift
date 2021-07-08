import UIKit

class UnderlineView: UIView {

    private static let defaultHeight: CGFloat = 1.0

    // MARK: - Overridden

    override var bounds: CGRect {
        didSet {
            layer.cornerRadius = bounds.height / 2.0
        }
    }

    override var intrinsicContentSize: CGSize {
        .init(width: UIView.noIntrinsicMetric, height: UnderlineView.defaultHeight)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        customInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        customInit()
    }
}

// MARK: - Private methods

private extension UnderlineView {
    func customInit() {
        setupView()
    }

    func setupView() {
        backgroundColor = Theme.Colors.dark.withAlphaComponent(0.1)
        layer.cornerRadius = UnderlineView.defaultHeight / 2.0
        layer.masksToBounds = true
    }
}
