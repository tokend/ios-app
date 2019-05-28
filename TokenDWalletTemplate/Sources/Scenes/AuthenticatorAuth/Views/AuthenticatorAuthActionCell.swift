import UIKit
import RxSwift

extension AuthenticatorAuth {
    
    class ActionCell: UIView {
        
        // MARK: - Public properties
        
        public var onActionButtonClicked: (() -> Void)?
        
        public var actionTitle: String? {
            didSet {
                self.actionButton.setTitle(self.actionTitle, for: .normal)
            }
        }
        
        // MARK: - Private properties
        
        private let actionButton: UIButton = UIButton()
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: - Override
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.setupView()
            self.setupButton()
            self.setupLayout()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupButton() {
            self.actionButton.backgroundColor = Theme.Colors.mainColor
            self.actionButton.setTitleColor(Theme.Colors.textOnAccentColor, for: .normal)
            self.actionButton.titleLabel?.font = Theme.Fonts.actionButtonFont
            self.actionButton
                .rx
                .controlEvent(.touchUpInside)
                .asDriver()
                .drive(onNext: { [weak self] in
                    self?.onActionButtonClicked?()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupLayout() {
            self.addSubview(self.actionButton)
            
            self.actionButton.snp.makeConstraints { (make) in
                make.leading.trailing.top.bottom.equalToSuperview().inset(20)
                make.height.equalTo(50)
            }
        }
    }
}
