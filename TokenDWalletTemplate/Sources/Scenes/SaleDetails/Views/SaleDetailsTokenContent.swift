import Foundation
import Nuke
import RxCocoa
import RxSwift
import SnapKit
import UIKit

extension SaleDetails {
    
    public typealias TokenCellModel = TitleValueTableViewCell.Model
    public typealias SectionViewModel = TransactionDetails.Model.SectionViewModel
    public typealias SectionModel = TransactionDetails.Model.SectionModel
    
    public enum TokenContent {
        
        public struct Model {
            
            public let assetName: String?
            public let assetCode: String
            public let imageUrl: URL?
            public let balanceState: BalanceState
            public let availableTokenAmount: Decimal
            public let issuedTokenAmount: Decimal
            public let maxTokenAmount: Decimal
        }
        
        public struct ViewModel {
            
            public let assetCode: String
            public let assetName: String?
            public let balanceStateImage: UIImage?
            public let iconUrl: URL?
            public let title: String
            public let sections: [SectionViewModel]
            
            public func setup(_ view: TokenContent.View) {
                view.tokenCode = self.assetCode
                view.tokenName = self.assetName
                view.iconUrl = self.iconUrl
                view.tokenBalanceStateImage = self.balanceStateImage
                view.title = self.title
                view.sections = self.sections
            }
        }
        
        public class View: UIView {
            
            // MARK: - Public properties
            
            public var title: String? {
                get { return self.titleLabel.text }
                set { self.titleLabel.text = newValue }
            }
            
            public var sections: [SectionViewModel] = [] {
                didSet {
                    self.tokenDetailsTableView.reloadData()
                    self.tokenDetailsTableView.snp.remakeConstraints { (make) in
                        make.leading.trailing.equalToSuperview()
                        make.top.equalTo(self.titleLabel.snp.bottom).offset(self.topInset)
                        make.bottom.equalToSuperview().inset(self.topInset)
                        make.height.equalTo(self.tableViewHeight)
                    }
                }
            }
            
            public var tokenCode: String? {
                didSet {
                    self.tokenCodeLabel.text = self.tokenCode
                }
            }
            
            public var tokenName: String? {
                didSet {
                    self.tokenNameLabel.text = self.tokenName
                    self.updateTokenAbbreviationLabel()
                }
            }
            
            public var tokenBalanceStateImage: UIImage? {
                didSet {
                    self.tokenBalanceStateIcon.image = self.tokenBalanceStateImage
                }
            }
            
            public var iconUrl: URL? = nil {
                didSet {
                    self.updateIcon()
                }
            }
            
            public var topHeight: CGFloat {
                return self.infoViewHeight + 2 * self.topInset
            }
            
            // MARK: - Private properties
            
            private let tokenInfoView: UIView = UIView()
            private let tokenIconContainerView: UIView = UIView()
            private let tokenIconView: UIImageView = UIImageView()
            
            private let tokenAbbreviationView: UIView = UIView()
            private let tokenAbbreviationLabel: UILabel = UILabel()
            
            private let labelContainerView: UIView = UIView()
            private let tokenCodeLabel: UILabel = UILabel()
            private let tokenNameLabel: UILabel = UILabel()
            
            private let tokenBalanceStateIcon: UIImageView = UIImageView()
            
            private let containerView: UIView = UIView()
            private let titleLabel: UILabel = UILabel()
            private let tokenDetailsTableView: UITableView = UITableView(frame: .zero, style: .grouped)
            
            private let iconSize: CGFloat = 45
            private let topInset: CGFloat = 15
            private let sideInset: CGFloat = 20
            private let infoViewHeight: CGFloat = 100
            
            private var tableViewHeight: CGFloat {
                return self.tokenDetailsTableView.contentSize.height
            }
            
            private var disposable: Disposable?
            
            // MARK: -
            
            override init(frame: CGRect) {
                super.init(frame: frame)
                self.commonInit()
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            deinit {
                self.disposable?.dispose()
                self.disposable = nil
            }
            
            private func commonInit() {
                self.setupView()
                self.setupTokenInfoView()
                self.setupIconView()
                self.setupTokenAbbreviationView()
                self.setupTokenAbbreviationLabel()
                self.setupLabelContainerView()
                self.setupTokenCodeLabel()
                self.setupTokenNameLabel()
                self.setupTokenBalanceStateIcon()
                self.setupContainerView()
                self.setupTitleLable()
                self.setupTokenDetailsTableView()
                self.setupLayout()
            }
            
            // MARK: - Override
            
            public override var intrinsicContentSize: CGSize {
                var size = self.tokenDetailsTableView.contentSize
                size.height += self.topHeight
                
                return size
            }
            
            public override func didMoveToSuperview() {
                super.didMoveToSuperview()
                
                if self.superview == nil {
                    self.unobserveContentSize()
                } else {
                    self.observeContentSize()
                }
            }
            
            // MARK: - Private
            
            private func updateIcon() {
                if let iconUrl = self.iconUrl {
                    self.tokenAbbreviationView.isHidden = true
                    Nuke.loadImage(
                        with: iconUrl,
                        into: self.tokenIconView
                    )
                } else {
                    Nuke.cancelRequest(for: self.tokenIconView)
                    self.tokenIconView.image = nil
                    self.tokenAbbreviationView.isHidden = false
                }
            }
            
            private func updateTokenAbbreviationLabel() {
                guard let code = self.tokenCode,
                    let firstCharacter = code.first else {
                        return
                }
                self.tokenAbbreviationView.backgroundColor = TokenColoringProvider.shared.coloringForCode(code)
                let abbreviation = "\(firstCharacter)".uppercased()
                self.tokenAbbreviationLabel.text = abbreviation
            }
            
            private func observeContentSize() {
                self.unobserveContentSize()
                
                self.disposable = self.tokenDetailsTableView
                    .rx
                    .observe(
                        CGSize.self,
                        "contentSize",
                        options: [.new],
                        retainSelf: false
                    )
                    .throttle(0.100, scheduler: MainScheduler.instance)
                    .subscribe { [weak self] _ in
                        self?.invalidateIntrinsicContentSize()
                    }
            }
            
            private func unobserveContentSize() {
                self.disposable?.dispose()
                self.disposable = nil
            }
            
            // MARK: - Setup
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.clear
            }
            
            private func setupTokenInfoView() {
                self.tokenInfoView.backgroundColor = Theme.Colors.contentBackgroundColor
            }
            
            private func setupIconView() {
                self.tokenIconView.contentMode = .scaleAspectFit
                self.tokenInfoView.layer.cornerRadius = 10.0
            }
            
            private func setupTokenAbbreviationView() {
                self.tokenAbbreviationView.layer.cornerRadius = self.iconSize / 2
                self.tokenAbbreviationView.isHidden = true
            }
            
            private func setupTokenAbbreviationLabel() {
                self.tokenAbbreviationLabel.textColor = Theme.Colors.textOnAccentColor
                self.tokenAbbreviationLabel.font = Theme.Fonts.largeTitleFont
                self.tokenAbbreviationLabel.textAlignment = .center
            }
            
            private func setupLabelContainerView() {
                self.labelContainerView.backgroundColor = Theme.Colors.contentBackgroundColor
            }
            
            private func setupTokenCodeLabel() {
                self.tokenCodeLabel.textAlignment = .left
                self.tokenCodeLabel.textColor = Theme.Colors.textOnContentBackgroundColor
                self.tokenCodeLabel.font = Theme.Fonts.largeTitleFont
                self.tokenCodeLabel.numberOfLines = 0
                self.tokenCodeLabel.setContentHuggingPriority(.required, for: .vertical)
                self.tokenCodeLabel.setContentCompressionResistancePriority(.required, for: .vertical)
                self.tokenCodeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            }
            
            private func setupTokenBalanceStateIcon() {
                self.tokenBalanceStateIcon.contentMode = .center
            }
            
            private func setupTokenNameLabel() {
                self.tokenNameLabel.textAlignment = .left
                self.tokenNameLabel.textColor = Theme.Colors.textOnContentBackgroundColor
                self.tokenNameLabel.font = Theme.Fonts.plainTextFont
                self.tokenNameLabel.numberOfLines = 0
                self.tokenNameLabel.setContentCompressionResistancePriority(.required, for: .vertical)
                self.tokenNameLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            }
            
            private func setupContainerView() {
                self.containerView.backgroundColor = Theme.Colors.contentBackgroundColor
                self.containerView.layer.cornerRadius = 10.0
            }
            
            private func setupTitleLable() {
                self.titleLabel.backgroundColor = Theme.Colors.contentBackgroundColor
                self.titleLabel.font = Theme.Fonts.largeTitleFont
            }
            
            private func setupTokenDetailsTableView() {
                let cellClasses: [CellViewAnyModel.Type] = [
                    TokenCellModel.self
                ]
                self.tokenDetailsTableView.register(classes: cellClasses)
                self.tokenDetailsTableView.dataSource = self
                self.tokenDetailsTableView.delegate = self
                self.tokenDetailsTableView.rowHeight = UITableView.automaticDimension
                self.tokenDetailsTableView.estimatedRowHeight = 15
                self.tokenDetailsTableView.backgroundColor = Theme.Colors.contentBackgroundColor
                self.tokenDetailsTableView.isUserInteractionEnabled = false
                self.tokenDetailsTableView.separatorStyle = .none
            }
            
            private func setupLayout() {
                self.addSubview(self.tokenInfoView)
                self.setupTokenInfoViewLayout()
                
                self.addSubview(self.containerView)
                self.containerView.addSubview(self.titleLabel)
                self.containerView.addSubview(self.tokenDetailsTableView)
                
                self.tokenInfoView.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalToSuperview().inset(self.topInset)
                    make.height.equalTo(self.infoViewHeight)
                }
                
                self.containerView.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalTo(self.tokenInfoView.snp.bottom).offset(self.topInset)
                    make.bottom.equalToSuperview()
                }
                
                self.titleLabel.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalToSuperview().inset(self.topInset)
                }
                
                self.tokenDetailsTableView.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview()
                    make.top.equalTo(self.titleLabel.snp.bottom)
                    make.bottom.equalToSuperview().inset(10.0)
                }
            }
            
            private func setupTokenInfoViewLayout() {
                self.tokenInfoView.addSubview(self.tokenIconContainerView)
                self.setupTokenIconContainerViewLayout()
                
                self.tokenInfoView.addSubview(self.labelContainerView)
                self.setupLabelContainerViewLayout()
                
                self.tokenInfoView.addSubview(self.tokenBalanceStateIcon)
                
                self.tokenBalanceStateIcon.setContentCompressionResistancePriority(
                    .defaultHigh,
                    for: .horizontal
                )
                self.labelContainerView.setContentCompressionResistancePriority(
                    .defaultLow,
                    for: .horizontal
                )
                
                self.tokenBalanceStateIcon.setContentHuggingPriority(
                    .defaultHigh,
                    for: .horizontal
                )
                self.labelContainerView.setContentHuggingPriority(
                    .defaultLow,
                    for: .horizontal
                )
                
                self.tokenIconContainerView.snp.makeConstraints { (make) in
                    make.leading.equalToSuperview().inset(self.sideInset)
                    make.top.equalToSuperview().inset(self.topInset)
                    make.width.height.equalTo(self.iconSize)
                }
                
                self.labelContainerView.snp.makeConstraints { (make) in
                    make.leading.equalTo(self.tokenIconContainerView.snp.trailing).offset(self.sideInset)
                    make.top.equalTo(self.tokenIconContainerView)
                }
                
                self.tokenBalanceStateIcon.snp.makeConstraints { (make) in
                    make.leading.equalTo(self.labelContainerView.snp.trailing).offset(self.sideInset)
                    make.trailing.equalToSuperview().inset(self.sideInset)
                    make.centerY.equalToSuperview()
                    make.height.equalTo(30.0)
                }
            }
            
            private func setupTokenIconContainerViewLayout() {
                self.tokenIconContainerView.addSubview(self.tokenIconView)
                
                self.tokenIconContainerView.addSubview(self.tokenAbbreviationView)
                self.setupTokenAbbreviationViewLayout()
                
                self.tokenIconView.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
                
                self.tokenAbbreviationView.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
            }
            
            private func setupLabelContainerViewLayout() {
                self.labelContainerView.addSubview(self.tokenCodeLabel)
                self.labelContainerView.addSubview(self.tokenNameLabel)
                
                self.tokenCodeLabel.snp.makeConstraints { (make) in
                    make.top.equalToSuperview()
                    make.leading.trailing.equalToSuperview()
                }
                
                self.tokenNameLabel.snp.makeConstraints { (make) in
                    make.top.equalTo(self.tokenCodeLabel.snp.bottom).offset(self.topInset)
                    make.leading.trailing.bottom.equalToSuperview()
                }
            }
            
            private func setupTokenAbbreviationViewLayout() {
                self.tokenAbbreviationView.addSubview(self.tokenAbbreviationLabel)
                
                self.tokenAbbreviationLabel.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
            }
        }
    }
}

extension SaleDetails.TokenContent.View: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].cells.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.sections[indexPath.section].cells[indexPath.row]
        let cell = tableView.dequeueReusableCell(with: model, for: indexPath)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section].title
    }
    
    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return self.sections[section].description
    }
}

extension SaleDetails.TokenContent.View: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView(frame: .zero)
        header.frame.size.height = 0.0
        return header
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView(frame: .zero)
        footer.frame.size.height = 0.0
        return footer
    }
}

extension SaleDetails.TokenContent {
    
    public enum BalanceState {
        
        case created
        case notCreated
    }
}
