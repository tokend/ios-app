import UIKit

protocol DashboardPendingOffersPreviewPlugInDisplayLogic: class {
    func displayDidSelectViewMore(viewModel: DashboardPendingOffersPreviewPlugIn.Event.DidSelectViewMore.ViewModel)
}

extension DashboardPendingOffersPreviewPlugIn {
    typealias DisplayLogic = DashboardPendingOffersPreviewPlugInDisplayLogic
    
    class ViewController: UIViewController {
        // MARK: - Private properties
        
        private let titleLabel: UILabel = UILabel()
        private let transactionsListContainerView: UIView = UIView()
        private let viewMoreButton: UIButton = UIButton()
        private let minimumTransactionsListHeight: CGFloat = 80
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        
        // MARK: - Public properties
        
        public var transactionsList: TransactionsListScene.ViewController? = nil {
            didSet {
                guard oldValue != self.transactionsList else {
                    return
                }
                if let old = oldValue {
                    self.removeOldTransactionsList(old)
                }
                if let new = self.transactionsList {
                    self.addNewTransactionsList(new)
                }
            }
        }
        
        // MARK: -
        
        func inject(interactorDispatch: InteractorDispatch?, routing: Routing?) {
            self.interactorDispatch = interactorDispatch
            self.routing = routing
        }
        
        // MARK: - Overridden
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.setupView()
            self.setupTitleLabel()
            self.setupViewMoreButton()
            self.setupLayout()
        }
        
        // MARK: - Private
        
        private func removeOldTransactionsList(_ old: TransactionsListScene.ViewController) {
            old.onContentSizeDidChange = nil
            self.removeChildViewController(old)
        }
        
        private func addNewTransactionsList(_ new: TransactionsListScene.ViewController) {
            self.addChild(
                new,
                to: self.transactionsListContainerView,
                layoutFulledge: true
            )
            
            new.scrollEnabled = false
            new.onContentSizeDidChange = { [weak new] (newSize) in
                new?.view.snp.remakeConstraints({ [weak self] (make) in
                    make.edges.equalToSuperview()
                    make.height.equalTo(max(newSize.height, self?.minimumTransactionsListHeight ?? 0))
                })
            }
        }
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupTitleLabel() {
            self.titleLabel.textColor = Theme.Colors.sideTextOnContentBackgroundColor
            self.titleLabel.font = Theme.Fonts.largeTitleFont
            self.titleLabel.text = Localized(.pending_order)
            self.titleLabel.numberOfLines = 0
        }
        
        private func setupViewMoreButton() {
            let buttonImage = UIImage.resizableImageWithColor(Theme.Colors.actionButtonColor)
            self.viewMoreButton.setBackgroundImage(buttonImage, for: .normal)
            self.viewMoreButton.titleLabel?.font = Theme.Fonts.actionButtonFont
            self.viewMoreButton.setTitleColor(Theme.Colors.actionTitleButtonColor, for: .normal)
            self.viewMoreButton.setTitle(Localized(.view_more), for: .normal)
            self.viewMoreButton.addTarget(
                self,
                action: #selector(self.viewMoreButtonAction),
                for: .touchUpInside
            )
        }
        
        private func setupLayout() {
            let contentView = self.view
            
            contentView?.addSubview(self.titleLabel)
            contentView?.addSubview(self.transactionsListContainerView)
            contentView?.addSubview(self.viewMoreButton)
            
            self.titleLabel.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(15)
                make.top.equalToSuperview().inset(16)
            }
            
            self.transactionsListContainerView.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(self.titleLabel.snp.bottom).offset(12)
            }
            
            self.viewMoreButton.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(15)
                make.bottom.equalToSuperview().inset(12)
                make.top.equalTo(self.transactionsListContainerView.snp.bottom).offset(12)
                make.height.greaterThanOrEqualTo(44.0)
            }
        }
        
        @objc private func viewMoreButtonAction() {
            self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                let request = DashboardPendingOffersPreviewPlugIn.Event.DidSelectViewMore.Request()
                businessLogic.onDidSelectViewMore(request: request)
            })
        }
    }
}

extension DashboardPendingOffersPreviewPlugIn.ViewController: DashboardPendingOffersPreviewPlugIn.DisplayLogic {
    func displayDidSelectViewMore(viewModel: DashboardPendingOffersPreviewPlugIn.Event.DidSelectViewMore.ViewModel) {
        self.routing?.onViewMoreAction()
    }
}

extension DashboardPendingOffersPreviewPlugIn.ViewController: DashboardScene.PlugIn {
    var type: DashboardPlugInType {
        return .viewController(self)
    }
    
    func reloadData() {
        self.transactionsList?.reloadTransactions()
    }
}
