import Foundation
import UIKit
import RxSwift
import Down

extension SaleDetails {
    
    enum OverviewTab {
        struct Model {
            let contentText: String
            let identifier: TabIdentifier
        }
        
        struct ViewModel {
            let contentText: String
            let identifier: TabIdentifier
            
            func setup(tab: OverviewTab.View) {
                tab.saleDescription = self.contentText
            }
        }
        
        class View: UIView {
            
            public var saleDescription: String? {
                get { return self.saleDescriptionLabel.text }
                set { self.handle(text: newValue) }
            }
            
            // MARK: Private
            
            private let saleDescriptionLabel: UILabel = UILabel()
            
            private let sideInset: CGFloat = 20
            private let topInset: CGFloat = 15
            
            // MARK: - Override
            
            override init(frame: CGRect) {
                super.init(frame: frame)
                
                self.commonInit()
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            private func commonInit() {
                self.setupView()
                self.setupSaleTokenNameLabel()
            }
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.contentBackgroundColor
            }
            
            private func setupSaleTokenNameLabel() {
                self.saleDescriptionLabel.font = Theme.Fonts.plainTextFont
                self.saleDescriptionLabel.font = self.saleDescriptionLabel.font.withSize(17)
                self.saleDescriptionLabel.textColor = Theme.Colors.textOnContentBackgroundColor
                self.saleDescriptionLabel.textAlignment = .left
                self.saleDescriptionLabel.lineBreakMode = .byWordWrapping
                self.saleDescriptionLabel.numberOfLines = 0
            }
            
            private func handle(text: String?) {
                guard let text = text else {
                    return
                }
                
                if let view = self.getMarkdownView(text: text) {
                    self.addSubview(view)
                    view.snp.makeConstraints { (make) in
                        make.edges.equalToSuperview()
                    }
                } else {
                    self.addSubview(self.saleDescriptionLabel)
                    self.saleDescriptionLabel.snp.makeConstraints { (make) in
                        make.leading.trailing.equalToSuperview().inset(self.sideInset)
                        make.top.equalToSuperview().offset(self.sideInset)
                    }
                    self.saleDescriptionLabel.text = self.saleDescription
                }
            }
            
            private func getMarkdownView(text: String) -> DownView? {
                return try? DownView(
                    frame: self.bounds,
                    markdownString: text,
                    openLinksInBrowser: false
                )
            }
        }
    }
}
