import UIKit
import RxSwift

extension Polls {
    
    public enum PollCell {
        
        public struct ViewModel: CellViewModel {
            let pollId: String
            let question: String
            let choicesViewModels: [Polls.PollsChoiceCell.ViewModel]
            let isVotable: Bool
            let actionTitle: String
            let actionType: Model.ActionType
            
            // MARK: - Public
            
            public func setup(cell: View) {
                cell.question = self.question
                cell.choices = self.choicesViewModels
                cell.isVotable = self.isVotable
                cell.actionTitle = self.actionTitle
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
            
            var choices: [Polls.PollsChoiceCell.ViewModel] = [] {
                didSet {
                    self.indexPathes.removeAll()
                    self.choicesTableView.reloadData()
                    self.choicesTableView.snp.updateConstraints { (make) in
                        make.height.equalTo(self.tableViewHeight)
                    }
                }
            }
            
            var isVotable: Bool = false {
                didSet {
                    self.choicesTableView.isUserInteractionEnabled = self.isVotable
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
            private let choicesTableView: UITableView = UITableView(
                frame: .zero,
                style: .grouped
            )
            private let actionButton: UIButton = UIButton()
            
            private let sideInset: CGFloat = 20.0
            private let topInset: CGFloat = 10.0
            private let buttonHeight: CGFloat = 44.0
            
            private var indexPathes: [IndexPath] = []
            private var tableViewHeight: CGFloat {
                let height = self.indexPathes.reduce(0.0, { (total, indexPath) -> CGFloat in
                    let height = self.choicesTableView.cellForRow(at: indexPath)?.frame.size.height ?? 0
                    return total + height
                })
                return height
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
                let isActionButtonEnabled: Bool
                if self.isVotable {
                    isActionButtonEnabled = !self.choices.allSatisfy({ (poll) -> Bool in
                        poll.isSelected == false
                    })
                } else {
                    isActionButtonEnabled = true
                }
                let titleColorAlpha: CGFloat = isActionButtonEnabled ? 1.0 : 0.25
                self.actionButton.setTitleColor(
                    Theme.Colors.accentColor.withAlphaComponent(titleColorAlpha),
                    for: .normal
                )
                self.actionButton.isEnabled = isActionButtonEnabled
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
            
            private func setupChoicesTableView() {
                self.choicesTableView.backgroundColor = Theme.Colors.clear
                self.choicesTableView.register(classes: [
                    Polls.PollsChoiceCell.ViewModel.self
                    ]
                )
                self.choicesTableView.delegate = self
                self.choicesTableView.dataSource = self
                self.choicesTableView.separatorStyle = .none
                self.choicesTableView.sectionHeaderHeight = 0.0
                self.choicesTableView.sectionFooterHeight = 0.0
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
                self.container.addSubview(self.choicesTableView)
                self.container.addSubview(self.actionButton)
                
                self.container.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.bottom.equalToSuperview()
                }
                
                self.questionLabel.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalToSuperview().inset(self.topInset)
                }
                
                self.choicesTableView.snp.makeConstraints { (make) in
                    make.leading.trailing.equalTo(self.questionLabel)
                    make.top.equalTo(self.questionLabel.snp.bottom).offset(-self.topInset)
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
        self.indexPathes.appendUnique(indexPath)
        let model = self.choices[indexPath.section]
        let cell = tableView.dequeueReusableCell(with: model, for: indexPath)
        return cell
    }
}
