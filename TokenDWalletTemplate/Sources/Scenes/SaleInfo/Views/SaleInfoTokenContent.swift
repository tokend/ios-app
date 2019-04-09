import Foundation
import UIKit
import SnapKit
import Nuke

extension SaleInfo {
    
    typealias TokenCellModel = TransactionDetailsCell.Model
    typealias SectionViewModel = TransactionDetails.Model.SectionViewModel
    typealias SectionModel = TransactionDetails.Model.SectionModel
    
    enum TokenContent {
        
        struct Model {
            let assetName: String?
            let assetCode: String
            let imageUrl: URL?
            let balanceState: BalanceState
            let availableTokenAmount: Decimal
            let issuedTokenAmount: Decimal
            let maxTokenAmount: Decimal
        }
        
        struct ViewModel {
            let assetCode: String
            let assetName: String?
            let balanceStateImage: UIImage?
            let iconUrl: URL?
            let sections: [SectionViewModel]
            
            func setup(_ view: TokenContent.View) {
                view.tokenCode = self.assetCode
                view.tokenName = self.assetName
                view.iconUrl = self.iconUrl
                view.tokenBalanceStateImage = self.balanceStateImage
                view.sections = self.sections
            }
        }
        
        class View: UIView {
            
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
                }
            }
            
            public var tokenBalanceStateImage: UIImage? {
                didSet {
                    self.tokenBalanceStateIcon.image = self.tokenBalanceStateImage
                }
            }
            
            public var iconUrl: URL? = nil {
                didSet {
                    if let iconUrl = self.iconUrl {
                        Nuke.loadImage(
                            with: iconUrl,
                            into: self.tokenIconView
                        )
                    } else {
                        self.tokenIconView.image = nil
                    }
                }
            }
            
            // MARK: - Override
            
            override init(frame: CGRect) {
                super.init(frame: frame)
                self.commonInit()
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            // MARK: - Private properties
            
            private let tokenInfoView: UIView = UIView()
            private let tokenIconContainerView: UIView = UIView()
            private let tokenIconView: UIImageView = UIImageView()
            
            private let labelStackView: UIView = UIView()
            private let tokenCodeLabel: UILabel = UILabel()
            private let tokenNameLabel: UILabel = UILabel()
            
            private let tokenBalanceStateIcon: UIImageView = UIImageView()
            
            private let tokenDetailsTableView: UITableView = UITableView(frame: .zero, style: .grouped)
            
            private let iconSize: CGFloat = 45
            private let topInset: CGFloat = 15
            private let sideInset: CGFloat = 20
            
            // MARK: - Private
            
            private func commonInit() {
                self.setupView()
                self.setupTokenInfoView()
                self.setupIconView()
                self.setupLabelStackView()
                self.setupTokenCodeLabel()
                self.setupTokenNameLabel()
                self.setupTokenDetailsTableView()
                self.setupLayout()
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
                self.tokenDetailsTableView.estimatedRowHeight = 125
                self.tokenDetailsTableView.tableFooterView = UIView(frame: CGRect.zero)
                self.tokenDetailsTableView.backgroundColor = Theme.Colors.containerBackgroundColor
                self.tokenDetailsTableView.isUserInteractionEnabled = false
            }
            
            private func setupLayout() {
                self.addSubview(self.tokenInfoView)
                self.tokenInfoView.addSubview(self.tokenIconContainerView)
                self.tokenIconView.addSubview(self.labelStackView)
                
                self.tokenIconContainerView.addSubview(self.tokenIconView)
                self.tokenInfoView.addSubview(self.tokenIconView)
                self.labelStackView.addSubview(self.tokenCodeLabel)
                self.labelStackView.addSubview(self.tokenNameLabel)
                
                self.tokenInfoView.addSubview(self.tokenBalanceStateIcon)
                
                self.addSubview(self.tokenDetailsTableView)
                
                self.tokenInfoView.snp.makeConstraints { (make) in
                    make.left.right.equalToSuperview()
                    make.top.equalToSuperview().inset(self.sideInset)
                    make.height.equalTo(100)
                }
                
                self.tokenIconView.snp.makeConstraints { (make) in
                    make.top.equalToSuperview().inset(self.topInset)
                    make.leading.equalToSuperview().inset(self.sideInset)
                    make.width.height.equalTo(self.iconSize)
                }
                
                self.labelStackView.snp.makeConstraints { (make) in
                    make.leading.equalTo(self.tokenIconView.snp.trailing).offset(self.sideInset)
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
                    make.right.equalToSuperview().inset(self.sideInset)
                    make.centerY.equalToSuperview()
                }
                
                self.tokenDetailsTableView.snp.makeConstraints { (make) in
                    make.top.equalTo(self.tokenInfoView.snp.bottom).offset(self.sideInset)
                    make.trailing.leading.bottom.equalToSuperview()
                }
            }
        }
    }
}

extension SaleInfo.TokenContent.View: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.sections[indexPath.section].cells[indexPath.row]
        let cell = tableView.dequeueReusableCell(with: model, for: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section].title
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return self.sections[section].description
    }
}

extension SaleInfo.TokenContent {
    enum BalanceState {
        case created
        case notCreated
    }
}
