import Foundation
import UIKit
import SnapKit

extension SaleDetails {
    
    public enum EmptyContent {
        
        public struct Model {
            
            public let message: String
        }
        
        public struct ViewModel {
            
            public let message: String
            
            public func setup(_ view: View) {
                view.message = self.message
            }
        }
        
        public class View: UIView {
            
            // MARK: - Override
            
            override init(frame: CGRect) {
                super.init(frame: frame)
                self.commonInit()
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            // MARK: - Public properties
            
            public var message: String? {
                didSet {
                    self.emptyContentLabel.text = self.message
                }
            }
            
            // MARK: - Private properties
            
            private let emptyContentLabel: UILabel = UILabel()
            
            // MARK: - Private
            
            private func commonInit() {
                self.setupView()
                self.setupEmptyContentLabel()
                self.setupLayout()
            }
            
            // MARK: - Setup
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.containerBackgroundColor
            }
            
            private func setupEmptyContentLabel() {
                self.emptyContentLabel.font = self.emptyContentLabel.font.withSize(17)
                self.emptyContentLabel.textColor = Theme.Colors.sideTextOnContainerBackgroundColor
                self.emptyContentLabel.font = Theme.Fonts.smallTextFont
                self.emptyContentLabel.textAlignment = .center
                self.emptyContentLabel.lineBreakMode = .byWordWrapping
                self.emptyContentLabel.numberOfLines = 0
            }
            
            private func setupLayout() {
                self.addSubview(self.emptyContentLabel)
                
                self.emptyContentLabel.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview().inset(15)
                }
            }
        }
    }
}
