import UIKit
import RxSwift
import RxCocoa

extension ConfirmationScene.View {
    class TitleBoolSwitchViewModel: ConfirmationScene.Model.CellViewModel, CellViewModel {
        
        // MARK: - Public properties
        
        var switchedOn: Bool = false
        
        // MARK: -
        
        init(
            hint: String?,
            cellType: ConfirmationScene.Model.CellModel.CellType,
            identifier: ConfirmationScene.CellIdentifier,
            switchedOn: Bool
            ) {
            
            self.switchedOn = switchedOn
            
            super.init(
                hint: hint,
                cellType: cellType,
                identifier: identifier
            )
        }
        
        func setup(cell: TitleBoolSwitchView) {
            cell.hint = self.hint
            cell.switchedOn = self.switchedOn
            cell.identifier = self.identifier
        }
    }
    
    class TitleBoolSwitchView: BaseCell {
        
        // MARK: - Public properties
        
        var hint: String? {
            get { return self.titleLabel.text }
            set { self.titleLabel.text = newValue }
        }
        
        var switchedOn: Bool {
            get { return self.switchView.isOn }
            set { self.switchView.isOn = newValue }
        }
        
        var identifier: ConfirmationScene.CellIdentifier?
        
        var onSwitch: ((_ identifier: ConfirmationScene.CellIdentifier, _ value: Bool) -> Void)?
        
        // MARK: - Private properties
        
        private let titleLabel: UILabel = UILabel()
        private let switchView: UISwitch = UISwitch()
        
        private let disposeBag = DisposeBag()
        
        // MARK: -
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
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
        
        // MARK: - Private
        
        // MARK: - Setup
        
        private func setupTitleLabel() {
            self.titleLabel.backgroundColor = Theme.Colors.contentBackgroundColor
            self.titleLabel.font = Theme.Fonts.plainTextFont
        }
        
        private func setupSwitchView() {
            self.switchView.onTintColor = Theme.Colors.accentColor
            self.switchView
                .rx
                .isOn
                .asDriver()
                .drive(onNext: { [weak self] value in
                    guard let identifier = self?.identifier else { return }
                    
                    self?.onSwitch?(identifier, value)
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
                make.leading.equalToSuperview().inset(self.sideInset * 2 + self.iconSize)
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
