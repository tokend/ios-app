import UIKit
import RxSwift

extension Polls {
    
    enum PollCell {
        
        public struct ViewModel: CellViewModel {
            let pollId: String
            let question: String
            let choicesViewModels: [Polls.PollsChoiceCell.ViewModel]
            let isVotable: Bool
            let actionTitle: String
            let buttonType: Model.ButtonType
            
            // MARK: - Public
            
            public func setup(cell: View) {
                cell.question = self.question
                cell.choices = self.choicesViewModels
                cell.isVotable = self.isVotable
                cell.actionTitle = self.actionTitle
                cell.buttonType = self.buttonType
            }
        }
        
        public class View: UITableViewCell {
            
            // MARK: - Public properties
            
            var onActionButtonClicked: ((Model.ButtonType) -> Void)?
            
            var question: String? {
                get { return self.questionLabel.text }
                set { self.questionLabel.text = newValue }
            }
            
            var choices: [Polls.PollsChoiceCell.ViewModel] = [] {
                didSet {
                    self.choicesTableView.reloadData()
                }
            }
            
            var isVotable: Bool = false {
                didSet {
                    self.choicesTableView.isUserInteractionEnabled = self.isVotable
                }
            }
            
            var actionTitle: String? {
                get { return self.actionButton.titleLabel?.text }
                set { self.actionButton.setTitle(newValue, for: .normal) }
            }
            
            var buttonType: Model.ButtonType?
            
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
            
            private let disposeBag: DisposeBag = DisposeBag()
            
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
                self.questionLabel.font = Theme.Fonts.largePlainTextFont
            }
            
            private func setupChoicesTableView() {
                self.choicesTableView.backgroundColor = Theme.Colors.contentBackgroundColor
                self.choicesTableView.register(classes: [
                    Polls.PollsChoiceCell.ViewModel.self
                    ]
                )
                self.choicesTableView.delegate = self
                self.choicesTableView.dataSource = self
                self.choicesTableView.separatorStyle = .none
                
            }
            
            private func setupActionButton() {
                self.actionButton.backgroundColor = Theme.Colors.contentBackgroundColor
                self.actionButton.setTitleColor(
                    Theme.Colors.accentColor,
                    for: .normal
                )
                self.actionButton
                    .rx
                    .tap
                    .asDriver()
                    .drive(onNext: { [weak self] _ in
                        guard let buttonType = self?.buttonType else {
                            return
                        }
                        self?.onActionButtonClicked?(buttonType)
                    })
                    .disposed(by: self.disposeBag)
            }
            
            private func setupLayout() {
                self.contentView.addSubview(self.container)
                self.container.addSubview(self.questionLabel)
                
                self.container.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.bottom.equalToSuperview()
                }
                
                self.questionLabel.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.bottom.equalToSuperview().inset(self.topInset)
                }
            }
        }
    }
}

extension Polls.PollCell.View: UITableViewDelegate {
    
}

extension Polls.PollCell.View: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.choices.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // TODO Think about select choice notification
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.choices[indexPath.section]
        let cell = tableView.dequeueReusableCell(with: model, for: indexPath)
        return cell
    }
}
