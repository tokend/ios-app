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
            public let sections: [SectionViewModel]
            
            public func setup(_ view: TokenContent.View) {
                view.tokenCode = self.assetCode
                view.tokenName = self.assetName
                view.iconUrl = self.iconUrl
                view.tokenBalanceStateImage = self.balanceStateImage
                view.sections = self.sections
            }
        }
        
        public class View: UIView {
            
            // MARK: - Public properties
            
            public var sections: [SectionViewModel] = [] {
                didSet {
                    self.tokenDetailsTableView.reloadData()
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
            
            private let labelStackView: UIView = UIView()
            private let tokenCodeLabel: UILabel = UILabel()
            private let tokenNameLabel: UILabel = UILabel()
            
            private let tokenBalanceStateIcon: UIImageView = UIImageView()
            
            private let tokenDetailsTableView: UITableView = UITableView(frame: .zero, style: .grouped)
            
            private let iconSize: CGFloat = 45
            private let topInset: CGFloat = 15
            private let sideInset: CGFloat = 20
            private let infoViewHeight: CGFloat = 100
            
            // MARK: -
            
            override init(frame: CGRect) {
                super.init(frame: frame)
                self.commonInit()
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            private func commonInit() {
                self.setupView()
                self.setupTokenInfoView()
                self.setupIconView()
                self.setupTokenAbbreviationView()
                self.setupTokenAbbreviationLabel()
                self.setupLabelStackView()
                self.setupTokenCodeLabel()
                self.setupTokenNameLabel()
                self.setupTokenDetailsTableView()
                self.setupLayout()
            }
            
            // MARK: - Override
            
            public override var intrinsicContentSize: CGSize {
                var size = self.tokenDetailsTableView.contentSize
                size.height += self.topHeight
                
                return size
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
            
            public func observeContentSize() -> Observable<(UIView?, CGSize)> {
                return self.tokenDetailsTableView
                    .rx
                    .observe(
                        CGSize.self,
                        "contentSize",
                        options: [.new],
                        retainSelf: false
                    ).map({ [weak self] (tableSize) -> (UIView?, CGSize) in
                        guard let sSelf = self, let tableSize = tableSize else {
                            return (nil, CGSize.zero)
                        }
                        
                        var size = tableSize
                        size.height += sSelf.topHeight
                        
                        return (sSelf, size)
                    })
            }
            
            // MARK: - Setup
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.containerBackgroundColor
            }
            
            private func setupTokenInfoView() {
                self.tokenInfoView.backgroundColor = Theme.Colors.contentBackgroundColor
            }
            
            private func setupIconView() {
                self.tokenIconView.contentMode = .scaleAspectFit
            }
            
            private func setupTokenAbbreviationView() {
                self.tokenAbbreviationView.layer.cornerRadius = self.iconSize / 2
                self.tokenAbbreviationView.isHidden = true
            }
            
            private func setupTokenAbbreviationLabel() {
                self.tokenAbbreviationLabel.textColor = Theme.Colors.textOnMainColor
                self.tokenAbbreviationLabel.font = Theme.Fonts.largeTitleFont
                self.tokenAbbreviationLabel.textAlignment = .center
            }
            
            private func setupLabelStackView() {
                self.labelStackView.backgroundColor = Theme.Colors.contentBackgroundColor
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
            
            private func setupTokenNameLabel() {
                self.tokenNameLabel.textAlignment = .left
                self.tokenNameLabel.textColor = Theme.Colors.textOnContentBackgroundColor
                self.tokenNameLabel.font = Theme.Fonts.plainTextFont
                self.tokenNameLabel.numberOfLines = 0
                self.tokenNameLabel.setContentCompressionResistancePriority(.required, for: .vertical)
                self.tokenNameLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            }
            
            private func setupTokenDetailsTableView() {
                let cellClasses: [CellViewAnyModel.Type] = [
                    TokenCellModel.self
                ]
                self.tokenDetailsTableView.register(classes: cellClasses)
                self.tokenDetailsTableView.dataSource = self
                self.tokenDetailsTableView.rowHeight = UITableView.automaticDimension
                self.tokenDetailsTableView.estimatedRowHeight = 35
                self.tokenDetailsTableView.tableFooterView = UIView(frame: CGRect.zero)
                self.tokenDetailsTableView.backgroundColor = Theme.Colors.containerBackgroundColor
                self.tokenDetailsTableView.isUserInteractionEnabled = false
            }
            
            private func setupLayout() {
                self.addSubview(self.tokenInfoView)
                self.tokenInfoView.addSubview(self.tokenIconContainerView)
                self.tokenInfoView.addSubview(self.labelStackView)
                
                self.tokenIconContainerView.addSubview(self.tokenIconView)
                self.tokenIconContainerView.addSubview(self.tokenAbbreviationView)
                
                self.tokenAbbreviationView.addSubview(self.tokenAbbreviationLabel)
                
                self.labelStackView.addSubview(self.tokenCodeLabel)
                self.labelStackView.addSubview(self.tokenNameLabel)
                
                self.tokenInfoView.addSubview(self.tokenBalanceStateIcon)
                
                self.addSubview(self.tokenDetailsTableView)
                
                self.tokenInfoView.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview()
                    make.top.equalToSuperview().inset(self.topInset)
                    make.height.equalTo(self.infoViewHeight)
                }
                
                self.tokenIconView.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
                
                self.tokenAbbreviationView.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
                
                self.tokenAbbreviationLabel.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
                
                self.tokenIconContainerView.snp.makeConstraints { (make) in
                    make.top.equalToSuperview().inset(self.topInset)
                    make.leading.equalToSuperview().inset(self.sideInset)
                    make.width.height.equalTo(self.iconSize)
                }
                
                self.labelStackView.snp.makeConstraints { (make) in
                    make.leading.equalTo(self.tokenIconContainerView.snp.trailing).offset(self.sideInset)
                    make.trailing.equalTo(self.tokenBalanceStateIcon).offset(self.sideInset)
                    make.top.equalTo(self.tokenIconView)
                }
                
                self.tokenCodeLabel.snp.makeConstraints { (make) in
                    make.top.equalToSuperview()
                    make.leading.trailing.equalToSuperview()
                }
                
                self.tokenNameLabel.snp.makeConstraints { (make) in
                    make.top.equalTo(self.tokenCodeLabel.snp.bottom).offset(self.topInset)
                    make.leading.trailing.equalToSuperview()
                }
                
                self.tokenBalanceStateIcon.snp.makeConstraints { (make) in
                    make.trailing.equalToSuperview().inset(self.sideInset)
                    make.centerY.equalToSuperview()
                }
                
                self.tokenDetailsTableView.snp.makeConstraints { (make) in
                    make.top.equalTo(self.tokenInfoView.snp.bottom).offset(self.topInset)
                    make.trailing.leading.bottom.equalToSuperview()
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

extension SaleDetails.TokenContent {
    
    public enum BalanceState {
        
        case created
        case notCreated
    }
}
