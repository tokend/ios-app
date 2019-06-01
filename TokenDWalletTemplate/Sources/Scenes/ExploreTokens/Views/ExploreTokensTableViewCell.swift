import UIKit
import SnapKit
import Nuke

enum ExploreTokensTableViewCell {
    struct Model: CellViewModel {
        
        let identifier: String
        
        let iconUrl: URL?
        let codeColor: UIColor
        let title: String
        let description: String?
        
        let actionButtonTitle: String
        let actionButtonLoading: Bool
        
        func setup(cell: View) {
            cell.iconUrl = self.iconUrl
            cell.codeColor = self.codeColor
            cell.titleString = self.title
            cell.descriptionString = self.description
            
            cell.actionButtonTitle = self.actionButtonTitle
            
            if self.actionButtonLoading {
                cell.showActionButtonLoading()
            } else {
                cell.hideActionButtonLoading()
            }
        }
    }
    
    class View: UITableViewCell {
        
        // MARK: - Closures
        
        typealias OnActionButtonClicked = (View) -> Void
        
        // MARK: - Private properties
        
        private let iconSize: CGFloat = 45
        
        private let containerView: UIView = UIView()
        
        private let topPartContainer: UIView = UIView()
        
        private let iconContainerView: UIView = UIView()
        private let iconView: UIImageView = UIImageView()
        private let abbreviationBackgroundView: UIView = UIView()
        private let abbreviationLabel: UILabel = UILabel()
        
        private let labelsStackView: UIStackView = UIStackView()
        private let titleLabel: UILabel = UILabel()
        private let descriptionLabel: UILabel = UILabel()
        
        private let separatorView: UIView = UIView()
        
        private let bottomPartContainer: UIView = UIView()
        
        private let actionButton: UIButton = UIButton(type: .system)
        
        // MARK: - Public properties
        
        public var iconUrl: URL? = nil {
            didSet {
                if let iconUrl = self.iconUrl {
                    self.showIconViewLoading()
                    Nuke.loadImage(
                        with: iconUrl,
                        into: self.iconView,
                        progress: nil,
                        completion: { [weak self] (_, _) in
                            self?.hideIconViewLoading()
                    })
                } else {
                    Nuke.cancelRequest(for: self.iconView)
                    self.iconView.image = nil
                    self.hideIconViewLoading()
                    self.updateAbbreviation()
                }
            }
        }
        public var codeColor: UIColor? {
            get {
                return self.abbreviationBackgroundView.backgroundColor
            }
            set {
                self.abbreviationBackgroundView.backgroundColor = newValue
            }
        }
        public var titleString: String = "" {
            didSet {
                self.titleLabel.text = self.titleString
                self.updateAbbreviation()
            }
        }
        public var descriptionString: String? = nil {
            didSet {
                self.descriptionLabel.text = self.descriptionString
                self.descriptionLabel.isHidden = self.descriptionString == nil
            }
        }
        public var actionButtonTitle: String = "" {
            didSet {
                self.actionButton.setTitle(self.actionButtonTitle, for: .normal)
            }
        }
        
        public var onActionButtonClicked: OnActionButtonClicked?
        
        // MARK: - Overridden methods
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            self.commonInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - Public
        
        public func showIconViewLoading() {
            self.iconContainerView.showLoading(tintColor: Theme.Colors.textOnAccentColor)
            self.iconView.alpha = 0.3
            self.abbreviationBackgroundView.alpha = 0.3
        }
        
        public func hideIconViewLoading() {
            self.iconContainerView.hideLoading()
            self.iconView.alpha = 1
            self.abbreviationBackgroundView.alpha = 1
        }
        
        public func showActionButtonLoading() {
            self.actionButton.showLoading()
            self.actionButton.isEnabled = false
        }
        
        public func hideActionButtonLoading() {
            self.actionButton.hideLoading()
            self.actionButton.isEnabled = true
        }
        
        // MARK: - Private
        
        private func commonInit() {
            self.setupView()
            self.setupContainerView()
            self.setupTopPartContainer()
            self.setupAbbreviationBackgroundView()
            self.setupAbbreviationLabel()
            self.setupIconView()
            self.setupLabelsStackView()
            self.setupTitleLabel()
            self.setupDescriptionLabel()
            self.setupSeparatorView()
            self.setupBottomPartContainer()
            self.setupActionButton()
            
            self.setupLayout()
        }
        
        private func setupView() {
            self.backgroundColor = Theme.Colors.clear
            self.selectionStyle = .none
        }
        
        private func setupContainerView() {
            self.containerView.backgroundColor = Theme.Colors.contentBackgroundColor
            self.containerView.layer.cornerRadius = 10.0
        }
        
        private func setupTopPartContainer() {
            self.topPartContainer.backgroundColor = Theme.Colors.contentBackgroundColor
            self.topPartContainer.layer.cornerRadius = 10.0
        }
        
        private func setupAbbreviationBackgroundView() {
            self.abbreviationBackgroundView.backgroundColor = Theme.Colors.mainColor
            self.abbreviationBackgroundView.layer.masksToBounds = true
            self.abbreviationBackgroundView.layer.cornerRadius = self.iconSize / 2
        }
        
        private func setupAbbreviationLabel() {
            self.abbreviationLabel.textAlignment = .center
            self.abbreviationLabel.numberOfLines = 1
            self.abbreviationLabel.textColor = Theme.Colors.contentBackgroundColor
            self.abbreviationLabel.font = Theme.Fonts.largeTitleFont
        }
        
        private func setupIconView() {
            self.iconView.layer.cornerRadius = self.iconSize / 2
            self.iconView.layer.masksToBounds = true
            self.iconView.contentMode = .scaleAspectFit
        }
        
        private func setupLabelsStackView() {
            self.labelsStackView.alignment = .fill
            self.labelsStackView.axis = .vertical
            self.labelsStackView.distribution = .fill
            self.labelsStackView.spacing = 8
        }
        
        private func setupTitleLabel() {
            self.titleLabel.textAlignment = .left
            self.titleLabel.textColor = Theme.Colors.textOnContentBackgroundColor
            self.titleLabel.font = Theme.Fonts.largeTitleFont
            self.titleLabel.numberOfLines = 0
            self.titleLabel.setContentHuggingPriority(.required, for: .vertical)
            self.titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            self.titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        
        private func setupDescriptionLabel() {
            self.descriptionLabel.textAlignment = .left
            self.descriptionLabel.textColor = Theme.Colors.textOnContentBackgroundColor
            self.descriptionLabel.font = Theme.Fonts.plainTextFont
            self.descriptionLabel.numberOfLines = 0
            self.descriptionLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            self.descriptionLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        
        private func setupSeparatorView() {
            self.separatorView.backgroundColor = Theme.Colors.separatorOnContentBackgroundColor
        }
        
        private func setupBottomPartContainer() {
            self.bottomPartContainer.backgroundColor = Theme.Colors.contentBackgroundColor
            self.bottomPartContainer.layer.cornerRadius = 10.0
        }
        
        private func setupActionButton() {
            self.actionButton.setTitleColor(Theme.Colors.disabledActionButtonColor, for: .disabled)
            self.actionButton.setTitleColor(Theme.Colors.actionButtonColor, for: .normal)
            self.actionButton.titleLabel?.font = Theme.Fonts.actionButtonFont
            self.actionButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 12, bottom: 15, right: 12)
            self.actionButton.addTarget(self, action: #selector(self.actionButtonAction), for: .touchUpInside)
        }
        
        @objc private func actionButtonAction() {
            self.onActionButtonClicked?(self)
        }
        
        private func setupLayout() {
            self.addSubview(self.containerView)
            self.containerView.addSubview(self.topPartContainer)
            self.containerView.addSubview(self.separatorView)
            self.containerView.addSubview(self.bottomPartContainer)
            
            self.topPartContainer.addSubview(self.iconContainerView)
            self.iconContainerView.addSubview(self.iconView)
            self.iconContainerView.addSubview(self.abbreviationBackgroundView)
            self.abbreviationBackgroundView.addSubview(self.abbreviationLabel)
            self.topPartContainer.addSubview(self.labelsStackView)
            self.bottomPartContainer.addSubview(self.actionButton)
            
            self.labelsStackView.addArrangedSubview(self.titleLabel)
            self.labelsStackView.addArrangedSubview(self.descriptionLabel)
            
            self.containerView.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(15)
                make.top.bottom.equalToSuperview()
            }
            
            self.topPartContainer.snp.makeConstraints { (make) in
                make.top.leading.trailing.equalToSuperview()
            }
            
            self.bottomPartContainer.snp.makeConstraints { (make) in
                make.bottom.leading.trailing.equalToSuperview()
            }
            
            self.separatorView.snp.makeConstraints { (make) in
                make.leading.equalTo(self.labelsStackView.snp.leading)
                make.trailing.equalToSuperview()
                make.top.equalTo(self.topPartContainer.snp.bottom)
                make.bottom.equalTo(self.bottomPartContainer.snp.top)
                make.height.equalTo(1.0 / UIScreen.main.scale)
            }
            
            let makeIconViewConstraints: (ConstraintMaker) -> Void = { [weak self] (make) in
                make.leading.equalToSuperview().inset(15)
                make.top.greaterThanOrEqualToSuperview().inset(15)
                make.bottom.lessThanOrEqualToSuperview().inset(15)
                make.centerY.equalToSuperview()
                make.height.equalTo(self?.iconSize ?? 0)
                make.width.equalTo(self?.iconSize ?? 0)
            }
            
            self.iconContainerView.snp.makeConstraints { (make) in
                makeIconViewConstraints(make)
            }
            
            self.abbreviationLabel.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
                make.center.equalToSuperview()
            }
            self.abbreviationBackgroundView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            
            self.iconView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            
            self.labelsStackView.snp.makeConstraints { (make) in
                make.top.bottom.trailing.equalToSuperview().inset(15)
                make.leading.equalTo(self.iconView.snp.trailing).offset(15)
            }
            
            self.actionButton.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
        
        private func updateAbbreviation() {
            if self.iconUrl == nil {
                self.abbreviationLabel.text = String(self.titleString.first ?? Character("D")).uppercased()
                self.abbreviationBackgroundView.isHidden = false
            } else {
                self.abbreviationBackgroundView.isHidden = true
            }
        }
    }
}
