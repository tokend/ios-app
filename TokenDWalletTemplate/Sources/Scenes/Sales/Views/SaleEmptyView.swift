import Foundation
import UIKit
import SnapKit

extension Sales {
    enum EmptyView {
        struct Model {
            let message: String
        }
        
        struct ViewModel {
            let message: String
            
            func setup(_ view: View) {
                view.message = self.message
            }
        }
        
        class View: UIView {
            
            // MARK: - Public properties
            
            public var message: String? {
                get { return self.emptyLabel.text }
                set { self.emptyLabel.text = newValue }
            }
            
            // MARK: - Private properties

            private let emptyLabel: UILabel = UILabel()
            
            // MARK: - Override

            override init(frame: CGRect) {
                super.init(frame: frame)
                self.commonInit()
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            // MARK: - Private
            
            private func commonInit() {
                self.setupView()
                self.setupEmptyLabel()
                self.setupLayout()
            }
            
            // MARK: - Setup
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.containerBackgroundColor
            }
            
            private func setupEmptyLabel() {
                self.emptyLabel.textColor = Theme.Colors.sideTextOnContainerBackgroundColor
                self.emptyLabel.font = Theme.Fonts.smallTextFont
                self.emptyLabel.textAlignment = .center
                self.emptyLabel.lineBreakMode = .byWordWrapping
                self.emptyLabel.numberOfLines = 0
            }
            
            private func setupLayout() {
                self.addSubview(self.emptyLabel)
                
                self.emptyLabel.snp.makeConstraints { (make) in
                    make.centerX.centerY.equalToSuperview()
                    make.leading.trailing.equalToSuperview().inset(15)
                }
            }
            
        }
    }
}
