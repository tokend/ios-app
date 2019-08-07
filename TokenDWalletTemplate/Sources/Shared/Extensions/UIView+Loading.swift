import UIKit

extension UIView {
    
    private static let maximumReusableIndicatorsNumber: Int = 10
    private static var reusableIndicators: [UIActivityIndicatorView] = []
    private static func enqueueReusableIndicator(_ indicator: UIActivityIndicatorView) {
        guard reusableIndicators.count < maximumReusableIndicatorsNumber
            else {
                return
        }
        reusableIndicators.append(indicator)
    }
    private static func dequeueReusableIndicator() -> UIActivityIndicatorView {
        guard reusableIndicators.count > 0
            else {
                reusableIndicators.append(createReusableIndicator())
                return dequeueReusableIndicator()
        }
        let indicator = reusableIndicators.removeFirst()
        return indicator
    }
    
    private static func createReusableIndicator() -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.setContentHuggingPriority(.defaultLow, for: .vertical)
        activityIndicator.setContentHuggingPriority(.defaultLow, for: .horizontal)
        activityIndicator.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        activityIndicator.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return activityIndicator
    }
    
    private static var indicators: [Int: UIActivityIndicatorView] = [:]
    
    @objc func showLoading(tintColor: UIColor? = nil) {
        let activityIndicator: UIActivityIndicatorView = {
            if let activity = UIView.indicators[hash] {
                return activity
            } else {
                let activityIndicator = UIView.dequeueReusableIndicator()
                UIView.indicators[hash] = activityIndicator
                return activityIndicator
            }
        }()
        
        activityIndicator.color = tintColor ?? UIColor.gray
        
        activityIndicator.startAnimating()
        self.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        self.isUserInteractionEnabled = false
    }
    
    @objc func hideLoading() {
        let activityIndicator = UIView.indicators.removeValue(forKey: hash)
        if let indicator = activityIndicator {
            indicator.stopAnimating()
            indicator.removeFromSuperview()
            UIView.enqueueReusableIndicator(indicator)
        }
        
        self.isUserInteractionEnabled = true
    }
}
