import UIKit
import RxSwift

extension Polls {
    
    public enum PollCell {
        
        public struct ViewModel: CellViewModel, Equatable {
            let pollId: String
            let question: String
            let subtitle: String?
            let choicesViewModels: [Polls.PollsChoiceCell.ViewModel]
            let isVotable: Bool
            let isActionEnabled: Bool
            let actionTitle: String
            let actionType: Model.ActionType
            
            // MARK: - Public
            
            public func setup(cell: View) {
                cell.question = self.question
                cell.subtitle = self.subtitle
                cell.choices = self.choicesViewModels
                cell.isVotable = self.isVotable
                cell.isActionEnabled = self.isActionEnabled
                cell.actionTitle = self.actionTitle
            }
            
            public static func == (lhs: PollCell.ViewModel, rhs: PollCell.ViewModel) -> Bool {
                return lhs.pollId == rhs.pollId
            }
        }
        
        public class View: UITableViewCell {
            
            // MARK: - Public properties
            
            var onActionButtonClicked: (() -> Void)?
            var onChoiceSelected: ((_ choiceValue: Int) -> Void)?
            
            var question: String? {
                get { return self.questionLabel.text }
                set { self.questionLabel.text = newValue }
            }
            
            var subtitle: String? {
                get { return self.subtitleLabel.text }
                set { self.subtitleLabel.text = newValue }
            }
            
            var choices: [Polls.PollsChoiceCell.ViewModel] = [] {
                didSet {
                    self.choicesTableView.reloadData()
                    self.choicesTableView.snp.updateConstraints { (make) in
                        make.height.equalTo(self.tableViewHeight)
                    }
                }
            }
            
            var isVotable: Bool = false {
                didSet {
                    self.choicesTableView.isUserInteractionEnabled = self.isVotable
                }
            }
            
            var isActionEnabled: Bool = false {
                didSet {
                    self.updateButtonVisibility()
                }
            }
            
            var actionTitle: String? {
                get { return self.actionButton.titleLabel?.text }
                set { self.actionButton.setTitle(newValue, for: .normal) }
            }
            
            // MARK: - Private properties
            
            private let container: UIView = UIView()
            private let questionLabel: UILabel = UILabel()
            private let subtitleLabel: UILabel = UILabel()
            private let choicesTableView: UITableView = UITableView(
                frame: .zero,
                style: .grouped
            )
            private let actionButton: UIButton = UIButton()
            
            private let sideInset: CGFloat = 20.0
            private let topInset: CGFloat = 10.0
            private let buttonHeight: CGFloat = 44.0
            
            private var tableViewHeight: CGFloat {
                return self.choicesTableView.contentSize.height + CGFloat(self.choices.count) * self.topInset / 2
            }
            
            private let disposeBag: DisposeBag = DisposeBag()
            
            private var selectedChoiceIndex: Int?
            
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
            
            private func commonInit() {
                self.setupView()
                self.setupContainer()
                self.setupQuestionLabel()
                self.setupSubtitleLabel()
                self.setupChoicesTableView()
                self.setupActionButton()
                self.setupLayout()
            }
            
            private func setSeletctedChoice(index: Int) {
                if let currentSelectedChoice = self.selectedChoiceIndex {
                    var unSelectedChoice = self.choices[currentSelectedChoice]
                    unSelectedChoice.isSelected = false
                    self.choices[currentSelectedChoice] = unSelectedChoice
                }
                self.selectedChoiceIndex = index
                var selectedChoice = self.choices[index]
                selectedChoice.isSelected = true
                self.choices[index] = selectedChoice
                self.choicesTableView.reloadData()
                self.updateButtonVisibility()
            }
            
            private func updateButtonVisibility() {
                let titleColorAlpha: CGFloat = self.isActionEnabled ? 1.0 : 0.25
                self.actionButton.setTitleColor(
                    Theme.Colors.accentColor.withAlphaComponent(titleColorAlpha),
                    for: .normal
                )
                self.actionButton.isEnabled = self.isActionEnabled
            }
            
            // MARK: - Setup
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.containerBackgroundColor
                self.selectionStyle = .none
            }
            
            private func setupContainer() {
                self.container.backgroundColor = Theme.Colors.contentBackgroundColor
                self.container.layer.cornerRadius = 10.0
            }
            
            private func setupQuestionLabel() {
                self.questionLabel.backgroundColor = Theme.Colors.contentBackgroundColor
                self.questionLabel.font = Theme.Fonts.largeTitleFont
                self.questionLabel.numberOfLines = 0
            }
            
            private func setupSubtitleLabel() {
                self.subtitleLabel.backgroundColor = Theme.Colors.contentBackgroundColor
                self.subtitleLabel.textColor = Theme.Colors.separatorOnContentBackgroundColor
                self.subtitleLabel.font = Theme.Fonts.largePlainTextFont
                self.subtitleLabel.numberOfLines = 1
            }
            
            private func setupChoicesTableView() {
                self.choicesTableView.backgroundColor = Theme.Colors.clear
                self.choicesTableView.register(classes: [
                    Polls.PollsChoiceCell.ViewModel.self
                    ]
                )
                self.choicesTableView.delegate = self
                self.choicesTableView.dataSource = self
                self.choicesTableView.estimatedRowHeight = 55.0
                self.choicesTableView.rowHeight = UITableView.automaticDimension
                self.choicesTableView.separatorStyle = .none
                self.choicesTableView.isScrollEnabled = false
            }
            
            private func setupActionButton() {
                self.actionButton.backgroundColor = Theme.Colors.contentBackgroundColor
                self.actionButton.setTitleColor(
                    Theme.Colors.accentColor,
                    for: .normal
                )
                self.actionButton.titleLabel?.font = Theme.Fonts.actionButtonFont
                self.actionButton
                    .rx
                    .tap
                    .asDriver()
                    .drive(onNext: { [weak self] _ in
                        self?.onActionButtonClicked?()
                    })
                    .disposed(by: self.disposeBag)
            }
            
            private func setupLayout() {
                self.contentView.addSubview(self.container)
                self.container.addSubview(self.questionLabel)
                self.container.addSubview(self.subtitleLabel)
                self.container.addSubview(self.choicesTableView)
                self.container.addSubview(self.actionButton)
                
                self.container.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.bottom.equalToSuperview()
                }
                
                self.questionLabel.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalToSuperview().inset(self.topInset * 2)
                }
                
                self.subtitleLabel.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalTo(self.questionLabel.snp.bottom).offset(self.topInset)
                }
                
                self.choicesTableView.snp.makeConstraints { (make) in
                    make.leading.trailing.equalTo(self.questionLabel)
                    make.top.equalTo(self.subtitleLabel.snp.bottom).offset(self.topInset * 2)
                    make.height.equalTo(self.tableViewHeight)
                }
                
                self.actionButton.snp.makeConstraints { (make) in
                    make.top.equalTo(self.choicesTableView.snp.bottom).offset(self.topInset)
                    make.leading.equalToSuperview().inset(self.sideInset)
                    make.bottom.equalToSuperview().inset(self.topInset)
                    make.height.equalTo(self.buttonHeight)
                }
            }
        }
    }
}

extension Polls.PollCell.View: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = self.choices[indexPath.section]
        self.onChoiceSelected?(model.choiceValue)
        self.setSeletctedChoice(index: indexPath.section)
        self.isActionEnabled = true
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
}

extension Polls.PollCell.View: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.choices.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.choices[indexPath.section]
        let cell = tableView.dequeueReusableCell(with: model, for: indexPath)
        return cell
    }
}
