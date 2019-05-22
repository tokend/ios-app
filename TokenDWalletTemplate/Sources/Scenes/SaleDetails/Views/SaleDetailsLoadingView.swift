import UIKit
import SnapKit
import Foundation

extension SaleDetails {
    
    public enum LoadingContent {
        
        public struct Model {}
        
        public struct ViewModel {}
        
        public class View: UIView {
            
            // MARK: - Override
            
            override init(frame: CGRect) {
                super.init(frame: frame)
                self.commonInit()
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            // MARK: - Private properties
            
            private let loadingView: UIActivityIndicatorView = UIActivityIndicatorView()
            
            // MARK: - Private
            
            private func commonInit() {
                self.setupView()
                self.setupIndicatorView()
                self.setupLayout()
            }
            
            // MARK: - Overridden
            
            public override var intrinsicContentSize: CGSize {
                var size = self.loadingView.intrinsicContentSize
                size.height += 30.0
                return size
            }
            
            // MARK: - Setup
            
            private func setupView() {
                self.backgroundColor = Theme.Colors.containerBackgroundColor
            }
            
            private func setupIndicatorView() {
                self.loadingView.color = Theme.Colors.neutralColor
                self.loadingView.startAnimating()
            }
            
            private func setupLayout() {
                self.addSubview(self.loadingView)
                
                self.loadingView.snp.makeConstraints { (make) in
                    make.center.equalToSuperview()
                }
            }
        }
    }
}
