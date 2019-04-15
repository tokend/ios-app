import UIKit

protocol DashboardPaymentsPlugInDisplayLogic: class {
    typealias Event = DashboardPaymentsPlugIn.Event
    
    func displayBalancesDidChange(viewModel: Event.BalancesDidChange.ViewModel)
    func displayDidSelectViewMore(viewModel: Event.DidSelectViewMore.ViewModel)
    func displaySelectedBalanceDidChange(viewModel: Event.SelectedBalanceDidChange.ViewModel)
    func displayViewMoreAvailabilityChanged(viewModel: Event.ViewMoreAvailabilityChanged.ViewModel)
}

extension DashboardPaymentsPlugIn {
    typealias DisplayLogic = DashboardPaymentsPlugInDisplayLogic
    
    class ViewController: UIViewController {
        
        typealias Event = DashboardPaymentsPlugIn.Event
        typealias Model = DashboardPaymentsPlugIn.Model
        
        // MARK: - Private properties
        
        private let balancePicker: HorizontalPicker = HorizontalPicker()
        private let labelsStackView: UIStackView = UIStackView()
        private let balanceLabel: UILabel = UILabel()
        private let rateLabel: UILabel = UILabel()
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
            self.setupBalanceLabel()
            self.setupRateLabel()
            self.setupLabelsStackView()
            self.setupBalancePicker()
            self.setupViewMoreButton()
            self.setupLayout()
            
            let request = Event.ViewDidLoadSync.Request()
            self.interactorDispatch?.sendSyncRequest { businessLogic in
                businessLogic.onViewDidLoadSync(request: request)
            }
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
        
        private func setupBalanceLabel() {
            self.balanceLabel.font = Theme.Fonts.flexibleHeaderTitleFont
            self.balanceLabel.textColor = Theme.Colors.textOnContentBackgroundColor
            self.balanceLabel.adjustsFontSizeToFitWidth = true
            self.balanceLabel.minimumScaleFactor = 0.1
            self.balanceLabel.numberOfLines = 1
            self.balanceLabel.textAlignment = .center
        }
        
        private func setupRateLabel() {
            self.rateLabel.font = Theme.Fonts.plainTextFont
            self.rateLabel.textColor = Theme.Colors.textOnContentBackgroundColor
            self.rateLabel.adjustsFontSizeToFitWidth = true
            self.rateLabel.minimumScaleFactor = 0.1
            self.rateLabel.numberOfLines = 1
            self.rateLabel.textAlignment = .center
        }
        
        private func setupLabelsStackView() {
            self.labelsStackView.alignment = .center
            self.labelsStackView.axis = .vertical
            self.labelsStackView.distribution = .fill
            self.labelsStackView.spacing = 4
        }
        
        private func setupBalancePicker() {
            self.balancePicker.backgroundColor = Theme.Colors.contentBackgroundColor
            self.balancePicker.tintColor = Theme.Colors.mainColor
        }
        
        private func setupViewMoreButton() {
            let buttonImage = UIImage.resizableImageWithColor(Theme.Colors.actionButtonColor)
            self.viewMoreButton.setBackgroundImage(buttonImage, for: .normal)
            let disabledButtonImage = UIImage.resizableImageWithColor(Theme.Colors.disabledActionButtonColor)
            self.viewMoreButton.setBackgroundImage(disabledButtonImage, for: .disabled)
            self.viewMoreButton.titleLabel?.font = Theme.Fonts.actionButtonFont
            self.viewMoreButton.setTitleColor(Theme.Colors.disabledActionTitleButtonColor, for: .disabled)
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
            
            contentView?.addSubview(self.balancePicker)
            contentView?.addSubview(self.labelsStackView)
            contentView?.addSubview(self.transactionsListContainerView)
            contentView?.addSubview(self.viewMoreButton)
            self.labelsStackView.addArrangedSubview(self.balanceLabel)
            self.labelsStackView.addArrangedSubview(self.rateLabel)
            
            self.balancePicker.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalToSuperview().inset(12)
            }
            
            self.labelsStackView.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(15)
                make.top.equalTo(self.balancePicker.snp.bottom).offset(20)
            }
            
            self.transactionsListContainerView.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(self.labelsStackView.snp.bottom).offset(15)
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
                let request = Event.DidSelectViewMore.Request()
                businessLogic.onDidSelectViewMore(request: request)
            })
        }
        
        private func setRate(_ rate: String?) {
            self.rateLabel.text = rate
        }
        
        private func setSelectedBalanceIfNeeded(index: Int?) {
            guard let index = index else {
                return
            }
            
            self.balancePicker.setSelectedItemAtIndex(index, animated: true)
        }
    }
}

extension DashboardPaymentsPlugIn.ViewController: DashboardPaymentsPlugIn.DisplayLogic {
    
    func displayBalancesDidChange(viewModel: Event.BalancesDidChange.ViewModel) {
        let items = viewModel.balances.map { (balance) -> HorizontalPicker.Item in
            return HorizontalPicker.Item(
                title: balance.name,
                enabled: balance.id != nil,
                onSelect: { [weak self] in
                    self?.transactionsList?.balanceId = balance.id
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        guard let id = balance.id else {
                            return
                        }
                        let request = Event.SelectedBalanceDidChange.Request(id: id)
                        businessLogic.onSelectedBalanceDidChange(request: request)
                    })
            })
        }
        self.balancePicker.items = items
        self.setSelectedBalanceIfNeeded(index: viewModel.selectedBalanceIndex)
    }
    
    func displaySelectedBalanceDidChange(viewModel: Event.SelectedBalanceDidChange.ViewModel) {
        self.balanceLabel.text = viewModel.balance
        self.rateLabel.text = viewModel.rate
        
        self.transactionsList?.asset = viewModel.asset
        self.transactionsList?.balanceId = viewModel.id
    }
    
    func displayDidSelectViewMore(viewModel: Event.DidSelectViewMore.ViewModel) {
        self.routing?.onViewMoreAction(viewModel.balanceId)
    }
    
    func displayViewMoreAvailabilityChanged(viewModel: Event.ViewMoreAvailabilityChanged.ViewModel) {
        self.viewMoreButton.isEnabled = viewModel.enabled
    }
}

extension DashboardPaymentsPlugIn.ViewController: DashboardScene.PlugIn {
    var type: DashboardPlugInType {
        return .viewController(self)
    }
    
    func reloadData() {
        self.transactionsList?.reloadTransactions()
        
        let request = Event.DidInitiateRefresh.Request()
        self.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
            businessLogic.onDidInitiateRefresh(request: request)
        })
    }
}
