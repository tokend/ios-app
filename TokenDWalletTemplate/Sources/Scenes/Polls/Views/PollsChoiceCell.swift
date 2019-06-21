import UIKit

extension Polls {
    
    public enum PollsChoiceCell {
        
        public struct ViewModel: CellViewModel {
            let name: String
            let choiceValue: Int
            let isSelected: Bool
            let result: Result?
            
            public struct Result {
                let percentageText: String
                let percentage: Float
            }
            
            public func setup(cell: View) {
                cell.title = self.name
                cell.isChoiceSelected = self.isSelected
                cell.result = self.result
            }
        }
        
        public class View: UITableViewCell {
            
            // MARK: - Public properties
            
            var title: String? {
                get { return self.titleLabel.text }
                set { self.titleLabel.text = newValue }
            }
            
            var isChoiceSelected: Bool? {
                didSet {
                    self.updateChoiceView()
                }
            }
            
            var result: ViewModel.Result? {
                didSet {
                    self.updateResult()
                }
            }
            
            // MARK: - Private properties
            
            private let choiceView: UIView = UIView()
            private let titleLabel: UILabel = UILabel()
            private let choicePercentageProgress: UIProgressView = UIProgressView()
            private let choicePercentageLabel: UILabel = UILabel()
            
            private let sideInset: CGFloat = 15.0
            private let topInset: CGFloat = 7.5
            
            // MARK: -
            
            public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)
                
                self.commonInit()
            }
            
            required init?(coder aDecoder: NSCoder) {
                super.init(coder: aDecoder)
                
                self.commonInit()
            }
            
            // MARK: - Private
            
            private func updateChoiceView() {
                guard let isSelected = self.isChoiceSelected else {
                    self.choiceView.layer.borderColor = Theme.Colors.containerBackgroundColor.cgColor
                    return
                }
                let borderColor = isSelected ?
                    Theme.Colors.accentColor.cgColor :
                    Theme.Colors.containerBackgroundColor.cgColor
                self.choiceView.layer.borderColor = borderColor
            }
            
            private func updateResult() {
                guard let result = self.result else {
                    self.choicePercentageLabel.isHidden = true
                    self.choicePercentageProgress.isHidden = true
                    return
                }
                self.choicePercentageLabel.isHidden = false
                self.choicePercentageProgress.isHidden = false
                
                self.choicePercentageLabel.text = result.percentageText
                self.choicePercentageProgress.progress = result.percentage
            }
            
            private func commonInit() {
                self.setupView()
                self.setupChoiceView()
                self.setupTitleLabel()
                self.setupChoicePercentageProgress()
                self.setupChoicePercentageLabel()
                self.setupLayout()
            }
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.contentBackgroundColor
                self.selectionStyle = .none
            }
            
            private func setupChoiceView() {
                self.choiceView.backgroundColor = Theme.Colors.contentBackgroundColor
                self.choiceView.layer.borderWidth = 2.0
                self.choiceView.layer.borderColor = Theme.Colors.containerBackgroundColor.cgColor
                self.choiceView.layer.cornerRadius = 7.5
            }
            
            private func setupTitleLabel() {
                self.titleLabel.backgroundColor = Theme.Colors.contentBackgroundColor
                self.titleLabel.font = Theme.Fonts.largePlainTextFont
            }
            
            private func setupChoicePercentageProgress() {
                self.choicePercentageProgress.progressTintColor = Theme.Colors.accentColor.withAlphaComponent(0.25)
                self.choicePercentageProgress.layer.cornerRadius = 7.5
            }
            
            private func setupChoicePercentageLabel() {
                self.choicePercentageLabel.backgroundColor = Theme.Colors.contentBackgroundColor
                self.choicePercentageLabel.font = Theme.Fonts.smallTextFont
                self.choicePercentageLabel.textColor = Theme.Colors.separatorOnContentBackgroundColor
            }
            
            private func setupLayout() {
                self.addSubview(self.choiceView)
                self.addSubview(self.choicePercentageLabel)
                
                self.choiceView.addSubview(self.choicePercentageProgress)
                self.choiceView.addSubview(self.titleLabel)
                
                self.choiceView.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalToSuperview().inset(self.topInset)
                }
                
                self.choicePercentageLabel.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalTo(self.choiceView.snp.bottom).offset(self.topInset)
                    make.bottom.equalToSuperview().inset(self.topInset)
                }
                
                self.choicePercentageProgress.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
                
                self.titleLabel.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.bottom.equalToSuperview().inset(self.topInset)
                }
            }
        }
    }
}
