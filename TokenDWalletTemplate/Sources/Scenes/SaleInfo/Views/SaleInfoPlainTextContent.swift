import Foundation
import UIKit
import RxSwift
import Down

extension SaleInfo {
    enum PlainTextContent {
        
        struct Model {
            let contentText: String
        }
        
        struct ViewModel {
            let contentText: String
            
            func setup(_ view: PlainTextContent.View) {
                view.saleDescription = self.contentText
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
                self.setupLayout()
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
            
            private func setupLayout() {
                self.addSubview(self.saleDescriptionLabel)
                
                self.saleDescriptionLabel.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(self.sideInset)
                    make.top.equalToSuperview().offset(self.sideInset)
                }
            }
            
            private func handle(text: String?) {
                guard let text = text else {
                    return
                }
                
                if let view = self.getMarkdownView(text: text) {
                    self.saleDescriptionLabel.isHidden = true
                    self.addSubview(view)

                    view.snp.makeConstraints { (make) in
                        make.edges.equalToSuperview()
                    }
                } else {
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
