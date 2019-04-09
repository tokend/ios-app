import RxCocoa
import RxSwift
import SnapKit
import UIKit

extension RegisterScene.View {
    
    class AgreeOnTermsView: UIView {
        
        // MARK: - Public properties
        
        var checked: Bool = false {
            didSet {
                self.updateCheckmarkState()
            }
        }
        
        var onAgreeChecked: ((_ checked: Bool) -> Void)?
        var onAction: (() -> Void)?
        
        // MARK: - Private properties
        
        private let containerView: UIView = UIView()
        private let checkmarkOutlineView: UIView = UIView()
        private let checkmarkButton: UIButton = UIButton(type: .custom)
        private let titleLabel: UILabel = UILabel()
        private let actionButton: UIButton = UIButton()
        
        private let disposeBag = DisposeBag()
        
        // MARK: -
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.customInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            
            self.customInit()
        }
        
        private func customInit() {
            self.setupView()
            self.setupContainerView()
            self.setupCheckmarkOutlineView()
            self.setupCheckmarkButton()
            self.setupTitleLabel()
            self.setupActionButton()
            self.setupLayout()
            self.updateCheckmarkState()
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.backgroundColor = UIColor.clear
        }
        
        private func setupContainerView() {
            self.containerView.backgroundColor = UIColor.clear
        }
        
        private func setupCheckmarkOutlineView() {
            self.checkmarkOutlineView.backgroundColor = Theme.Colors.separatorOnContentBackgroundColor
            self.checkmarkOutlineView.isUserInteractionEnabled = false
        }
        
        private func setupCheckmarkButton() {
            self.checkmarkButton.backgroundColor = Theme.Colors.contentBackgroundColor
            self.checkmarkButton.tintColor = Theme.Colors.textOnContainerBackgroundColor
            let imageInset: CGFloat = 3.0
            self.checkmarkButton.contentEdgeInsets = UIEdgeInsets(
                top: imageInset, left: imageInset,
                bottom: imageInset, right: imageInset
            )
            self.checkmarkButton.contentMode = .scaleAspectFit
            self.checkmarkButton.rx
                .controlEvent(.touchUpInside)
                .asDriver()
                .drive(onNext: { [weak self] in
                    let checked = !(self?.checked ?? false)
                    self?.checked = checked
                    self?.onAgreeChecked?(checked)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupTitleLabel() {
            let title = NSMutableAttributedString()
            
            let firstPart = NSAttributedString(
                string: Localized(.i_agree_on_the),
                attributes: [
                    NSAttributedString.Key.foregroundColor: Theme.Colors.textOnContainerBackgroundColor,
                    NSAttributedString.Key.font: Theme.Fonts.plainTextFont
                ]
            )
            title.append(firstPart)
            
            let secondPart = NSAttributedString(
                string: Localized(.terms_of_service),
                attributes: [
                    NSAttributedString.Key.foregroundColor: Theme.Colors.actionButtonColor,
                    NSAttributedString.Key.font: Theme.Fonts.plainTextFont,
                    NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
                ]
            )
            title.append(secondPart)
            
            self.titleLabel.textAlignment = .left
            self.titleLabel.attributedText = title
        }
        
        private func setupActionButton() {
            self.actionButton.rx
                .controlEvent(.touchUpInside)
                .asDriver()
                .drive(onNext: { [weak self] in
                    self?.onAction?()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupLayout() {
            self.addSubview(self.containerView)
            self.containerView.addSubview(self.checkmarkOutlineView)
            self.containerView.addSubview(self.checkmarkButton)
            self.containerView.addSubview(self.titleLabel)
            self.containerView.addSubview(self.actionButton)
            
            let offset: CGFloat = 20.0
            let checkmarkSize: CGFloat = 20.0
            let outlineWidth: CGFloat = 1.0
            
            self.checkmarkOutlineView.snp.makeConstraints { (make) in
                make.leading.centerY.equalToSuperview()
                make.size.equalTo(checkmarkSize)
            }
            
            self.checkmarkButton.snp.makeConstraints { (make) in
                make.edges.equalTo(self.checkmarkOutlineView).inset(outlineWidth)
            }
            
            self.titleLabel.snp.makeConstraints { (make) in
                make.leading.equalTo(self.checkmarkOutlineView.snp.trailing).offset(offset)
                make.top.bottom.trailing.equalToSuperview()
            }
            
            self.actionButton.snp.makeConstraints { (make) in
                make.edges.equalTo(self.titleLabel)
            }
            
            self.containerView.snp.makeConstraints { (make) in
                make.top.bottom.centerX.equalToSuperview()
            }
        }
        
        private func updateCheckmarkState() {
            let image: UIImage? = self.checked ? #imageLiteral(resourceName: "Checkmark") : nil
            self.checkmarkButton.setImage(image, for: .normal)
        }
    }
}
