import UIKit
import RxSwift

extension Polls {
    
    public class NavigationTitleView: UIView {
        
        // MARK: - Public properties
        
        var onPickerSelected: (() -> Void)?
        
        // MARK: - Private properties
        
        private let labelsContainer: UIView = UIView()
        private let pollsLabel: UILabel = UILabel()
        private let assetLabel: UILabel = UILabel()
        private let pickerButton: UIButton = UIButton(type: .system)
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        private let sideInset: CGFloat = 10.0
        private let topInset: CGFloat = 5.0
        private let buttonSize: CGFloat = 24.0
        
        // MARK: -
        
        public override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.setupView()
            self.setupLabelsContainer()
            self.setupPollsLabel()
            self.setupAssetLabel()
            self.setupPickerButton()
            self.setupLayout()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            
            self.setupView()
            self.setupLabelsContainer()
            self.setupPollsLabel()
            self.setupAssetLabel()
            self.setupPickerButton()
            self.setupLayout()
        }
        
        // MARK: - Public
        
        public func setAsset(asset: String) {
            self.assetLabel.text = asset
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupLabelsContainer() {
            self.labelsContainer.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupPollsLabel() {
            self.pollsLabel.backgroundColor = Theme.Colors.contentBackgroundColor
            self.pollsLabel.font = Theme.Fonts.plainBoldTextFont
            self.pollsLabel.text = Localized(.polls)
            self.pollsLabel.textAlignment = .center
        }
        
        private func setupAssetLabel() {
            self.assetLabel.backgroundColor = Theme.Colors.contentBackgroundColor
            self.assetLabel.textColor = Theme.Colors.separatorOnContentBackgroundColor
            self.assetLabel.font = Theme.Fonts.plainTextFont
            self.pollsLabel.textAlignment = .center
        }
        
        private func setupPickerButton() {
            self.pickerButton.backgroundColor = Theme.Colors.contentBackgroundColor
            self.pickerButton.tintColor = Theme.Colors.darkAccentColor
            self.pickerButton.setImage(
                Assets.drop.image,
                for: .normal
            )
            self.pickerButton
                .rx
                .tap
                .asDriver()
                .drive(onNext: { [weak self] (_) in
                    self?.onPickerSelected?()
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupLayout() {
            self.addSubview(self.labelsContainer)
            self.labelsContainer.addSubview(self.pollsLabel)
            self.labelsContainer.addSubview(self.assetLabel)
            self.addSubview(self.pickerButton)
            
            self.labelsContainer.snp.makeConstraints { (make) in
                make.top.bottom.equalToSuperview()
                make.centerX.equalToSuperview()
            }
            
            self.pollsLabel.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalToSuperview().inset(self.topInset)
                make.height.equalTo(17.5)
            }
            
            self.assetLabel.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(self.pollsLabel.snp.bottom).offset(self.topInset)
                make.bottom.equalToSuperview().inset(self.topInset)
            }
            
            self.pickerButton.snp.makeConstraints { (make) in
                make.leading.equalTo(self.labelsContainer.snp.trailing).offset(self.sideInset)
                make.trailing.equalToSuperview()
                make.bottom.equalToSuperview()
                make.width.height.equalTo(self.buttonSize)
            }
        }
    }
}
