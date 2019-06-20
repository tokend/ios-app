import UIKit

extension Polls {
    
    enum PollCell {
        
        public struct ViewModel: CellViewModel {
            let topic: String
            
            // MARK: - Public
            
            public func setup(cell: View) {
                cell.topic = self.topic
            }
        }
        
        public class View: UITableViewCell {
            
            // MARK: - Public properties
            
            var topic: String? {
                get { return self.topicLabel.text }
                set { self.topicLabel.text = newValue }
            }
            
            // MARK: - Private properties
            
            private let container: UIView = UIView()
            private let topicLabel: UILabel = UILabel()
            
            private let sideInset: CGFloat = 20.0
            private let topInset: CGFloat = 20.0
            
            // MARK: -
            
            public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)
                
                self.setupView()
                self.setupContainer()
                self.setupTopicLabel()
                self.setupLayout()
            }
            
            required init?(coder aDecoder: NSCoder) {
                super.init(coder: aDecoder)
                
                self.setupView()
                self.setupContainer()
                self.setupTopicLabel()
                self.setupLayout()
            }
            
            // MARK: - Private
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.containerBackgroundColor
                self.selectionStyle = .none
            }
            
            private func setupContainer() {
                self.container.backgroundColor = Theme.Colors.contentBackgroundColor
                self.container.layer.cornerRadius = 5
            }
            
            private func setupTopicLabel() {
                self.topicLabel.backgroundColor = Theme.Colors.contentBackgroundColor
                self.topicLabel.font = Theme.Fonts.largePlainTextFont
            }
            
            private func setupLayout() {
                self.contentView.addSubview(self.container)
                self.container.addSubview(self.topicLabel)
                
                self.container.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.bottom.equalToSuperview()
                }
                
                self.topicLabel.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.bottom.equalToSuperview().inset(self.topInset)
                }
            }
        }
    }
}
