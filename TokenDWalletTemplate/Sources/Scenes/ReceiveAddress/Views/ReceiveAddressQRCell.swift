import UIKit

extension ReceiveAddress {
    class QRCell: UIView {
        
        // MARK: - Private properties
        
        private let qrImageView: UIImageView = UIImageView()
        private let qrImageTapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer()
        private let valueLabel: BXFInteractiveLabel = BXFInteractiveLabel()
        private let statusLabel: BXFLabelWithInsets = BXFLabelWithInsets()
        
        private let sharingImageQueue = OperationQueue()
        
        // MARK: - Public properties
        
        public var onQRTap: (() -> Void)?
        
        public var qrCodeSize: CGSize {
            return self.qrImageView.bounds.size
        }
        
        public var numberOfLinesInValue: Int = 0 {
            didSet {
                self.valueLabel.numberOfLines = self.numberOfLinesInValue
            }
        }
        
        public var valueLabelText: String? {
            get { return self.valueLabel.text }
            set { self.valueLabel.text = newValue }
        }
        
        public var copyActionTitle: String {
            get { return self.valueLabel.copyAction.title }
            set { self.valueLabel.copyAction.title = newValue }
        }
        
        public var shareActionTitle: String {
            get { return self.valueLabel.shareAction.title }
            set { self.valueLabel.shareAction.title = newValue }
        }
        
        public var copyAction: (() -> Void)? {
            get { return self.valueLabel.copyAction.action }
            set { self.valueLabel.copyAction.action = newValue }
        }
        
        public var shareAction: (() -> Void)? {
            get { return self.valueLabel.shareAction.action }
            set { self.valueLabel.shareAction.action = newValue }
        }
        
        // MARK: - Overridden methods
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.commonInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - Public
        
        public func setQRImage(_ qr: UIImage, animated: Bool) {
            self.qrImageView.image = qr
            if self.qrImageView.alpha != 1 {
                let duration: TimeInterval = animated ? TimeInterval(UINavigationController.hideShowBarDuration) : 0
                UIView.animate(withDuration: duration) {
                    self.qrImageView.alpha = 1
                }
            }
        }
        
        public func showTemporaryTextAndDisableTapGesture(_ text: String) {
            self.disableGestureRecognizer()
            self.setStatusText(text) { [weak self] in
                self?.enableGestureRecognizer()
            }
        }
        
        // MARK: - Private
        
        private func disableGestureRecognizer() {
            self.qrImageTapGestureRecognizer.isEnabled = false
        }
        
        private func enableGestureRecognizer() {
            self.qrImageTapGestureRecognizer.isEnabled = true
        }
        
        private func setStatusText(_ text: String, completion: (() -> Void)?) {
            self.statusLabel.text = text
            
            self.switchLabel(
                self.valueLabel,
                withLabel: self.statusLabel
            ) {
                DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(0.5)) { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.switchLabel(
                        strongSelf.statusLabel,
                        withLabel: strongSelf.valueLabel,
                        completion: completion
                    )
                }
            }
        }
        
        private func switchLabel(
            _ labelToHide: UILabel,
            withLabel labelToShow: UILabel,
            completion: (() -> Void)?
            ) {
            
            self.showLabel(
                false,
                label: labelToHide
            ) { [weak self] in
                self?.showLabel(
                    true,
                    label: labelToShow,
                    completion: completion
                )
            }
        }
        
        private func showLabel(
            _ show: Bool,
            label: UILabel,
            completion: (() -> Void)?
            ) {
            
            UIView.animate(
                withDuration: TimeInterval(UINavigationController.hideShowBarDuration),
                delay: 0,
                options: [show ? .curveEaseIn : .curveEaseOut],
                animations: {
                    label.alpha = show ? 1 : 0
            }) { (_) in
                completion?()
            }
        }
        
        private func commonInit() {
            self.sharingImageQueue.maxConcurrentOperationCount = 1
            self.sharingImageQueue.qualityOfService = .userInteractive
            
            self.setupCell()
            self.setupQRImageView()
            self.setupQRImageTapGesture()
            self.setupValueLabel()
            self.setupStatusLabel()
            self.setupLayout()
        }
        
        private func setupQRImageTapGesture() {
            self.qrImageTapGestureRecognizer.cancelsTouchesInView = true
            self.qrImageTapGestureRecognizer.addTarget(self, action: #selector(self.qrImageTapAction))
            self.qrImageView.addGestureRecognizer(self.qrImageTapGestureRecognizer)
        }
        
        @objc private func qrImageTapAction() {
            self.onQRTap?()
        }
        
        private func setupCell() {
            self.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupQRImageView() {
            self.qrImageView.alpha = 0
            self.qrImageView.contentMode = .scaleToFill
        }
        
        private let labelTopBottomInsets: CGFloat = 10
        
        private func setupValueLabel() {
            self.valueLabel.topTextInset = labelTopBottomInsets
            self.valueLabel.bottomTextInset = labelTopBottomInsets
            self.valueLabel.textAlignment = .center
            self.valueLabel.textColor = Theme.Colors.sideTextOnContentBackgroundColor
            self.valueLabel.font = Theme.Fonts.smallTextFont
            self.valueLabel.numberOfLines = self.numberOfLinesInValue
            self.valueLabel.adjustsFontSizeToFitWidth = true
        }
        
        private func setupStatusLabel() {
            self.statusLabel.topTextInset = labelTopBottomInsets
            self.statusLabel.bottomTextInset = labelTopBottomInsets
            self.statusLabel.textAlignment = .center
            self.statusLabel.textColor = Theme.Colors.sideTextOnContentBackgroundColor
            self.statusLabel.numberOfLines = 0
            self.statusLabel.alpha = 0
        }
        
        private func setupLayout() {
            self.addSubview(self.qrImageView)
            self.qrImageView.snp.makeConstraints { (make) in
                make.top.equalToSuperview().inset(8)
                make.leading.trailing.equalToSuperview().inset(7)
                make.height.equalTo(self.qrImageView.snp.width)
            }
            
            self.addSubview(self.valueLabel)
            self.valueLabel.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(15)
                make.top.equalTo(self.qrImageView.snp.bottom).offset(12)
                make.bottom.equalToSuperview()
            }
            
            self.addSubview(self.statusLabel)
            self.statusLabel.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(15)
                make.center.equalTo(self.valueLabel.snp.center)
            }
        }
    }
}
