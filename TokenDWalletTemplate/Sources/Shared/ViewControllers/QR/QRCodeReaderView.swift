import UIKit
import QRCodeReader

final class QRCodeReaderView: UIView, QRCodeReaderDisplayable {
    
    // MARK: - Public properties
    
    public lazy var overlayView: UIView? = {
        return QRCodeReaderOverlayView()
    }()
    
    public let cameraView: UIView = {
        let cameraView = UIView()
        
        cameraView.clipsToBounds = true
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        
        return cameraView
    }()
    
    public lazy var cancelButton: UIButton? = {
        return self.getButton(with: #imageLiteral(resourceName: "Close icon"))
    }()
    
    public lazy var switchCameraButton: UIButton? = {
        return self.getButton(with: nil)
    }()
    
    public lazy var toggleTorchButton: UIButton? = {
        return self.getButton(with: #imageLiteral(resourceName: "Flash Light icon"))
    }()
    
    // MARK: - Public
    
    public func setupComponents(
        showCancelButton: Bool,
        showSwitchCameraButton: Bool,
        showTorchButton: Bool,
        showOverlayView: Bool,
        reader: QRCodeReader?
        ) {
        
        self.reader = reader
        
        self.addComponents()
        
        self.cancelButton?.isHidden = !showCancelButton
        self.switchCameraButton?.isHidden = !showSwitchCameraButton
        self.toggleTorchButton?.isHidden = !showTorchButton
        self.overlayView?.isHidden = !showOverlayView
        
        guard let overlayView = self.overlayView else { return }
    
        self.cameraView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        overlayView.snp.makeConstraints({ (make) in
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().inset(108)
        })
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        self.reader?.previewLayer.frame = self.bounds
    }
    
    // MARK: - Private properties
    
    private weak var reader: QRCodeReader?
    
    // MARK: - Private

    private func getButton(with image: UIImage?) -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(image, for: .normal)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        button.tintColor = UIColor.white
        button.layer.cornerRadius = 12
        
        button.snp.makeConstraints { (make) in
            make.width.equalTo(60)
            make.height.equalTo(60)
        }
        
        return button
    }
    
    private func getLabel(with text: String?) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.font = Theme.Fonts.plainTextFont
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 1.4
        
        label.attributedText = NSAttributedString(
            string: (text ?? ""),
            attributes: [NSAttributedString.Key.paragraphStyle: paragraph]
        )
        
        return label
    }
    
    // MARK: - Scan Result Indication
    
    func startTimerForBorderReset() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) { [weak self] in
            if let overlayView = self?.overlayView as? QRCodeReaderOverlayView {
                overlayView.overlayColor = .white
            }
        }
    }
    
    func addRedBorder() {
        self.startTimerForBorderReset()
        if let overlayView = self.overlayView as? QRCodeReaderOverlayView {
            overlayView.overlayColor = .red
        }
    }
    
    func addGreenBorder() {
        self.startTimerForBorderReset()
        if let overlayView = self.overlayView as? QRCodeReaderOverlayView {
            overlayView.overlayColor = .green
        }
    }
    
    @objc func orientationDidChange() {
        self.setNeedsDisplay()
        
        self.overlayView?.setNeedsDisplay()
        
        if let connection = self.reader?.previewLayer.connection, connection.isVideoOrientationSupported {
            let application = UIApplication.shared
            let orientation = UIDevice.current.orientation
            let supportedInterfaceOrientations = application.supportedInterfaceOrientations(
                for: application.keyWindow
            )
            
            connection.videoOrientation = QRCodeReader.videoOrientation(
                deviceOrientation: orientation,
                withSupportedOrientations: supportedInterfaceOrientations,
                fallbackOrientation: connection.videoOrientation
            )
        }
    }
    
    // MARK: - Convenience Methods
    
    private func addComponents() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(QRCodeReaderView.orientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil)
        
        self.addSubview(self.cameraView)
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        
        self.addSubview(stackView)
        
        let sideMargin: CGFloat = 64
        
        stackView.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().inset(24)
            make.leading.equalToSuperview().inset(sideMargin)
            make.trailing.equalToSuperview().inset(sideMargin)
            make.height.equalTo(60)
        }
        
        if let cancelButton = self.cancelButton {
            stackView.addArrangedSubview(cancelButton)
        }
        
        if let toggleTorchButton = self.toggleTorchButton {
            stackView.addArrangedSubview(toggleTorchButton)
        }
        
        if let switchCameraButton = self.switchCameraButton {
            stackView.addArrangedSubview(switchCameraButton)
        }
        
        if let overlayView = self.overlayView {
            self.addSubview(overlayView)
        }
        
        if let reader = self.reader {
            self.cameraView.layer.insertSublayer(reader.previewLayer, at: 0)
            
            self.orientationDidChange()
        }
    }
}
