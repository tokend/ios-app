import UIKit
import RxSwift
import RxCocoa

extension ConfirmationScene.View {
    class TitleBoolSwitchViewModel: ConfirmationScene.Model.CellViewModel {
        
        // MARK: - Public properties
        
        var value: Bool = false
        
        // MARK: -
        
        init(
            title: String,
            cellType: ConfirmationScene.Model.CellModel.CellType,
            identifier: ConfirmationScene.CellIdentifier,
            value: Bool
            ) {
            
            self.value = value
            
            super.init(
                title: title,
                cellType: cellType,
                identifier: identifier
            )
        }
    }
    
    class TitleBoolSwitchView: UIView {
        
        // MARK: - Public properties
        
        var model: TitleBoolSwitchViewModel? {
            didSet {
                self.updateFromModel()
            }
        }
        
        var onSwitch: ((_ identifier: ConfirmationScene.CellIdentifier, _ value: Bool) -> Void)?
        
        // MARK: - Private properties
        
        private let titleLabel: UILabel = UILabel()
        private let switchView: UISwitch = UISwitch()
        
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
            self.setupTitleLabel()
            self.setupSwitchView()
            self.setupLayout()
        }
        
        // MARK: - Public
        
        // MARK: - Private
        
        private func updateFromModel() {
            self.titleLabel.text = self.model?.title
            self.switchView.isOn = self.model?.value ?? false
        }
        
        // MARK: - Setup
        
        private func setupView() {
            self.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupTitleLabel() {
            SharedViewsBuilder.configureInputForm(titleLabel: self.titleLabel)
        }
        
        private func setupSwitchView() {
            self.switchView
                .rx
                .isOn
                .asDriver()
                .drive(onNext: { [weak self] value in
                    guard let model = self?.model else { return }
                    
                    self?.onSwitch?(model.identifier, value)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupLayout() {
            self.addSubview(self.titleLabel)
            self.addSubview(self.switchView)
            
            self.titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            self.switchView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            
            self.titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            self.switchView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            
            self.titleLabel.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().inset(20.0)
                make.centerY.equalToSuperview()
                make.top.bottom.equalToSuperview().inset(14.0)
            }
            
            self.switchView.snp.makeConstraints { (make) in
                make.leading.equalTo(self.titleLabel.snp.trailing).offset(10.0)
                make.centerY.equalTo(self.titleLabel)
                make.trailing.equalToSuperview().inset(20.0)
            }
        }
    }
}
