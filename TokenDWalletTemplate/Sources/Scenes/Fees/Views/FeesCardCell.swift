import UIKit

extension Fees {
    
    enum CardView {
        
        struct CardViewModel: CellViewModel {
            let title: String
            let subTitle: String
            let cells: [FeeCell.ViewModel]
            
            func setup(cell: View) {
                cell.title = self.title
                cell.subTitle = self.subTitle
                cell.cells = self.cells
            }
        }
        
        class View: UITableViewCell {
            
            // MARK: - Public properties
            
            public var title: String? {
                get { return self.titleLabel.text }
                set { self.titleLabel.text = newValue }
            }
            
            public var subTitle: String? {
                get { return self.subTitleLabel.text }
                set { self.subTitleLabel.text = newValue }
            }
            
            public var cells: [CellViewAnyModel] = [] {
                didSet {
                    self.tableView.reloadData()
                    self.tableView.snp.updateConstraints({ (make) in
                        make.height.equalTo(self.tableViewHeight)
                    })
                }
            }
            
            // MARK: - Private properties
            
            private let container: UIView = UIView()
            private let titleLabel: UILabel = UILabel()
            private let subTitleLabel: UILabel = UILabel()
            private let tableView: UITableView = UITableView(frame: .zero, style: .grouped)
            
            private let sideInset: CGFloat = 15.0
            private let topInset: CGFloat = 10.0
            private let sectionHeaderHeight: CGFloat = 10.0
            
            private var tableViewHeight: CGFloat {
                let cellsCount = self.cells.count
                let rowHeight = self.tableView.estimatedRowHeight + self.sectionHeaderHeight
                return CGFloat(cellsCount) * rowHeight
            }
            
            // MARK: -
            
            override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)
                
                self.setupView()
                self.setupContainerView()
                self.setupTitleLabel()
                self.setupSubTitleLabel()
                self.setupTableView()
                self.setupLayout()
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            // MARK: - Private
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.clear
                self.selectionStyle = .none
            }
            
            private func setupContainerView() {
                self.container.backgroundColor = Theme.Colors.contentBackgroundColor
                self.container.layer.cornerRadius = 10.0
            }
            
            private func setupTitleLabel() {
                self.titleLabel.backgroundColor = Theme.Colors.contentBackgroundColor
                self.titleLabel.font = Theme.Fonts.largeTitleFont
            }
            
            private func setupSubTitleLabel() {
                self.subTitleLabel.backgroundColor = Theme.Colors.contentBackgroundColor
                self.subTitleLabel.font = Theme.Fonts.plainTextFont
            }
            
            private func setupTableView() {
                self.tableView.backgroundColor = Theme.Colors.contentBackgroundColor
                self.tableView.register(classes: [
                        FeeCell.ViewModel.self
                    ]
                )
                self.tableView.dataSource = self
                self.tableView.delegate = self
                self.tableView.separatorStyle = .none
                self.tableView.isScrollEnabled = false
                self.tableView.estimatedRowHeight = 85.0
                self.tableView.rowHeight = UITableView.automaticDimension
            }
            
            private func setupLayout() {
                self.contentView.addSubview(self.container)
                
                self.container.addSubview(self.titleLabel)
                self.container.addSubview(self.subTitleLabel)
                self.container.addSubview(self.tableView)
                
                self.container.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.bottom.equalToSuperview()
                }
                
                self.titleLabel.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalToSuperview().inset(self.topInset)
                }
                
                self.subTitleLabel.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalTo(self.titleLabel.snp.bottom).offset(self.topInset)
                    make.bottom.equalTo(self.tableView.snp.top)
                }
                
                self.tableView.setContentCompressionResistancePriority(.fittingSizeLevel, for: .vertical)
                self.tableView.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
                
                self.tableView.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview()
                    make.top.equalTo(self.subTitleLabel.snp.bottom)
                    make.bottom.equalToSuperview().inset(self.topInset)
                    make.height.equalTo(self.tableViewHeight)
                }
            }
        }
    }
}

extension Fees.CardView.View: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.cells.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.cells[indexPath.section]
        let cell = tableView.dequeueReusableCell(with: model, for: indexPath)
        return cell
    }
}

extension Fees.CardView.View: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
}
