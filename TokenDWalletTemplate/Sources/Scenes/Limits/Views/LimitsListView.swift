import UIKit

extension Limits {
    
    public class ListView: UIView {
        
        public enum Period: Int, Comparable {
            
            case day
            case week
            case month
            case year
            
            public static func < (lhs: Period, rhs: Period) -> Bool {
                return lhs.rawValue < rhs.rawValue
            }
        }
        
        // MARK: - Public properties
        
        public var title: String? {
            get { return self.titleLabel.text }
            set { self.titleLabel.text = newValue }
        }
        
        // MARK: - Private properties
        
        private let titleLabel: UILabel = UILabel()
        private var periodViews: [Period: PeriodView] = [:]
        
        // MARK: -
        
        public override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.customInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            
            self.customInit()
        }
        
        private func customInit() {
            self.setupView()
            self.setupTitleLabel()
            self.setupPeriodViews()
            self.setupLayout()
        }
        
        // MARK: - Public
        
        public func set(period: Period, progress: Float, progressTitle: String) {
            guard let periodView = self.periodViews[period] else {
                return
            }
            
            periodView.progress = progress
            periodView.progressTitle = progressTitle
        }
        
        // MARK: - Private
        
        private func setupView() {
            
        }
        
        private func setupTitleLabel() {
            
        }
        
        private func setupPeriodViews() {
            var periodViews: [Period: PeriodView] = [:]
            
            periodViews[.day] = self.setupPeriodView(title: "Day")
            periodViews[.week] = self.setupPeriodView(title: "Week")
            periodViews[.month] = self.setupPeriodView(title: "Month")
            periodViews[.year] = self.setupPeriodView(title: "Year")
            
            self.periodViews = periodViews
        }
        
        private func setupPeriodView(title: String) -> PeriodView {
            let periodView = PeriodView()
            
            periodView.title = title
            
            return periodView
        }
        
        private func setupLayout() {
            self.addSubview(self.titleLabel)
            
            self.titleLabel.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(14.0)
                make.top.equalToSuperview().inset(10.0)
            }
            
            let periods = Array(self.periodViews.keys).sorted()
            var previousView: UIView?
            for period in periods {
                guard let periodView = self.periodViews[period] else {
                    continue
                }
                
                self.addSubview(periodView)
                periodView.snp.makeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(14.0)
                    if let prev = previousView {
                        make.top.equalTo(prev.snp.bottom).offset(10.0)
                    } else {
                        make.top.equalToSuperview()
                    }
                }
                
                previousView = periodView
            }
            
            previousView?.snp.makeConstraints({ (make) in
                make.bottom.equalToSuperview()
            })
        }
    }
}

extension Limits.ListView {
    
    public class PeriodView: UIView {
        
        // MARK: - Public properties
        
        public var title: String? {
            get { return self.titleLabel.text }
            set { self.titleLabel.text = newValue }
        }
        
        public var progress: Float {
            get { return self.progressBar.progress }
            set { self.progressBar.progress = newValue }
        }
        
        public var progressTitle: String? {
            get { return self.progressTitleLabel.text }
            set { self.progressTitleLabel.text = newValue }
        }
        
        // MARK: - Private properties
        
        private let titleLabel: UILabel = UILabel()
        private let progressBar: UIProgressView = UIProgressView(progressViewStyle: .default)
        private let progressTitleLabel: UILabel = UILabel()
        
        // MARK: -
        
        public override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.customInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            
            self.customInit()
        }
        
        private func customInit() {
            self.setupView()
            self.setupTitleLabel()
            self.setupProgressBar()
            self.setupProgressTitleLabel()
            self.setupLayout()
        }
        
        // MARK: - Private
        
        private func setupView() {
            
        }
        
        private func setupTitleLabel() {
            
        }
        
        private func setupProgressBar() {
            
        }
        
        private func setupProgressTitleLabel() {
            
        }
        
        private func setupLayout() {
            self.addSubview(self.titleLabel)
            self.addSubview(self.progressBar)
            self.addSubview(self.progressTitleLabel)
            
            self.titleLabel.snp.makeConstraints { (make) in
                make
            }
        }
    }
}
