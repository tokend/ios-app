import Foundation
import UIKit
import RxSwift

extension SaleDetails {
    
    public enum GeneralContent {
        
        public typealias SectionViewModel = TransactionDetails.Model.SectionViewModel
        public typealias TitleValueCellModel = TitleValueTableViewCell.Model
        
        public struct Model {
            
            public let baseAsset: String
            public let defaultQuoteAsset: String
            public let hardCap: Decimal
            public let baseHardCap: Decimal
            public let softCap: Decimal
            public let startTime: Date
            public let endTime: Date
        }
        
        public struct ViewModel {
            
            public let title: String
            public let sections: [SectionViewModel]
            
            public func setup(_ view: View) {
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
                    self.saleDetailsTableView.reloadData()
                    self.saleDetailsTableView.snp.remakeConstraints { (make) in
                        make.leading.trailing.equalToSuperview()
                        make.top.equalTo(self.titleLabel.snp.bottom).offset(self.topInset)
                        make.bottom.equalToSuperview().inset(self.topInset)
                        make.height.equalTo(self.saleDetailsHeight)
                    }
                }
            }
            
            // MARK: - Private properties
            
            private let saleDetailsTableView: UITableView = UITableView(frame: .zero, style: .grouped)
            private let containerView: UIView = UIView()
            private let titleLabel: UILabel = UILabel()
            
            private let sideInset: CGFloat = 20.0
            private let topInset: CGFloat = 15.0
            
            private var saleDetailsHeight: CGFloat {
                return self.saleDetailsTableView.contentSize.height
            }
            
            private var disposable: Disposable?
            
            // MARK: -
            
            override init(frame: CGRect) {
                super.init(frame: frame)
                self.customInit()
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            public override var intrinsicContentSize: CGSize {
                return self.saleDetailsTableView.contentSize
            }
            
            private func customInit() {
                self.setupView()
                self.setupContainerView()
                self.setupTitleLable()
                self.setupSaleDetailsTableView()
                self.setupLayout()
            }
            
            // MARK: - Override
            
            public override func didMoveToSuperview() {
                super.didMoveToSuperview()
                
                if self.superview == nil {
                    self.unobserveContentSize()
                } else {
                    self.observeContentSize()
                }
            }
            
            // MARK: - Private
            
            private func observeContentSize() {
                self.unobserveContentSize()
                
                self.disposable = self.saleDetailsTableView
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
            
            private func setupContainerView() {
                self.containerView.backgroundColor = Theme.Colors.contentBackgroundColor
                self.containerView.layer.cornerRadius = 10.0
            }
            
            private func setupTitleLable() {
                self.titleLabel.backgroundColor = Theme.Colors.contentBackgroundColor
                self.titleLabel.font = Theme.Fonts.largeTitleFont
            }
            
            private func setupSaleDetailsTableView() {
                let cellClasses: [CellViewAnyModel.Type] = [
                    TitleValueCellModel.self
                ]
                self.saleDetailsTableView.register(classes: cellClasses)
                self.saleDetailsTableView.dataSource = self
                self.saleDetailsTableView.delegate = self
                self.saleDetailsTableView.rowHeight = UITableView.automaticDimension
                self.saleDetailsTableView.estimatedRowHeight = 20
                self.saleDetailsTableView.backgroundColor = Theme.Colors.contentBackgroundColor
                self.saleDetailsTableView.isUserInteractionEnabled = false
                self.saleDetailsTableView.separatorStyle = .none
                
                self.saleDetailsTableView.setContentHuggingPriority(
                    .defaultLow,
                    for: .vertical
                )
                self.saleDetailsTableView.setContentCompressionResistancePriority(
                    .defaultHigh,
                    for: .vertical
                )
            }
            
            private func setupLayout() {
                self.addSubview(self.containerView)
                self.containerView.addSubview(self.titleLabel)
                self.containerView.addSubview(self.saleDetailsTableView)
                
                self.containerView.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.bottom.equalToSuperview().inset(self.topInset)
                }
                
                self.titleLabel.snp.makeConstraints { (make) in
                    make.leading.equalToSuperview().inset(self.sideInset)
                    make.trailing.equalToSuperview()
                    make.top.equalToSuperview().inset(self.topInset)
                }
                
                self.saleDetailsTableView.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview()
                    make.top.equalTo(self.titleLabel.snp.bottom).offset(self.topInset)
                    make.bottom.equalToSuperview().inset(self.topInset)
                }
            }
        }
    }
}

extension SaleDetails.GeneralContent.View: UITableViewDataSource {
    
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

extension SaleDetails.GeneralContent.View: UITableViewDelegate {
    
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
