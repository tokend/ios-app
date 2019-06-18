import UIKit
import RxCocoa
import RxSwift

public protocol SaleInvestDisplayLogic: class {
    typealias Event = SaleInvest.Event
    
    func displaySceneUpdated(viewModel: Event.SceneUpdated.ViewModel)
    func displaySelectBalance(viewModel: Event.SelectBalance.ViewModel)
    func displayBalanceSelected(viewModel: Event.BalanceSelected.ViewModel)
    func displayInvestAction(viewModel: Event.InvestAction.ViewModel)
    func displayError(viewModel: Event.Error.ViewModel)
    func displayEditAmount(viewModel: Event.EditAmount.ViewModel)
    func displayShowPreviousInvest(viewModel: Event.ShowPreviousInvest.ViewModel)
}

extension SaleInvest {
    public typealias DisplayLogic = SaleInvestDisplayLogic
    
    @objc(SaleInvestViewController)
    public class ViewController: UIViewController {
        
        public typealias Event = SaleInvest.Event
        public typealias Model = SaleInvest.Model
        
        // MARK: - Private properties
        
        private let disposeBag = DisposeBag()
        
        private let containerView: UIView = UIView()
        private let investConatinerView: UIView = UIView()
        
        private let investButton: UIButton = UIButton()
        
        private let historyButton: UIBarButtonItem = UIBarButtonItem(
            image: Assets.history.image,
            style: .plain,
            target: nil,
            action: nil
        )
        
        private let helpButton: UIBarButtonItem = UIBarButtonItem(
            image: Assets.help.image,
            style: .plain,
            target: nil,
            action: nil
        )
        
        // Invest content views
        
        private let enterInvestAmountView: EnterInvestAmountView = EnterInvestAmountView()
        private let availableBalanceView: AvalableBalanceView = AvalableBalanceView()
        private let existingInvestmentsLabel: UILabel = UILabel()
        private let existingInvestmentsTableView: UITableView = UITableView(
            frame: .zero,
            style: .grouped
        )
        
        private var existingInvestments: [SaleInvest.ExistingInvestmentCell.ViewModel] = [] {
            didSet {
                self.existingInvestmentsTableView.reloadData()
                self.updateExistingInvestments()
            }
        }
        
        private let buttonHeight: CGFloat = 45.0
        private let sideInset: CGFloat = 20
        private let topInset: CGFloat = 15
        private let bottomInset: CGFloat = 15
        
        private var viewDidAppear: Bool = false
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        private var onDeinit: DeinitCompletion = nil
        
        public func inject(
            interactorDispatch: InteractorDispatch?,
            routing: Routing?,
            onDeinit: DeinitCompletion = nil
            ) {
            
            self.interactorDispatch = interactorDispatch
            self.routing = routing
            self.onDeinit = onDeinit
        }
        
        // MARK: - Overridden
        
        public override func viewDidLoad() {
            super.viewDidLoad()
            
            self.commonInit()
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        public override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            self.viewDidAppear = true
        }
        
        // MARK: - Private
        
        private func commonInit() {
            self.setupView()
            self.setupContainerView()
            self.setupInvestContainerView()
            self.setupInvestButton()
            self.setupAvailableBalanceView()
            self.setupEnterInvestAmountView()
            self.setupExistingInvestmentsLabel()
            self.setupExistingInvestmentsTableView()
            self.setupNavBarButtons()
            self.setupLayout()
            
            self.observeKeyboard()
        }
        
        private func observeKeyboard() {
            let keyboardObserver = KeyboardObserver(
                self,
                keyboardWillChange: { (attributes) in
                    let keyboardHeight = attributes.heightIn(view: self.view)
                    if attributes.showingIn(view: self.view) {
                        self.investButton.snp.remakeConstraints { (make) in
                            make.leading.trailing.equalToSuperview()
                            make.bottom.equalToSuperview().inset(keyboardHeight)
                            make.height.equalTo(self.buttonHeight)
                        }
                    } else {
                        self.investButton.snp.remakeConstraints { (make) in
                            make.leading.trailing.equalToSuperview()
                            make.bottom.equalTo(self.view.safeArea.bottom)
                            make.height.equalTo(self.buttonHeight)
                        }
                    }
                    
                    if self.viewDidAppear {
                        UIView.animate(withKeyboardAttributes: attributes, animations: {
                            self.view.layoutIfNeeded()
                        })
                    }
            })
            KeyboardController.shared.add(observer: keyboardObserver)
        }
        
        private func updateNavBarButtons(isCancellable: Bool) {
            if isCancellable {
                self.navigationItem.rightBarButtonItems = [
                    self.helpButton,
                    self.historyButton
                ]
            } else {
                self.navigationItem.rightBarButtonItems = [
                    self.helpButton
                ]
            }
        }
        
        private func updateExistingInvestments() {
            let cellsCount = CGFloat(self.existingInvestments.count)
            let cellHeight = self.existingInvestmentsTableView.estimatedRowHeight
            let estimatedHeight = cellsCount * cellHeight
            self.existingInvestmentsTableView.snp.remakeConstraints { (make) in
                make.leading.trailing.equalTo(self.existingInvestmentsLabel)
                make.top.equalTo(self.existingInvestmentsLabel.snp.bottom)
                make.bottom.equalToSuperview()
                make.height.equalTo(estimatedHeight)
            }
            self.existingInvestmentsLabel.isHidden = cellsCount == 0
        }
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.containerBackgroundColor
        }
        
        private func setupContainerView() {
            self.containerView.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupInvestContainerView() {
            self.investConatinerView.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupSeparatorView(separator: UIView) {
            separator.backgroundColor = Theme.Colors.separatorOnContentBackgroundColor
            separator.isUserInteractionEnabled = false
        }
        
        private func setupInvestButton() {
            SharedViewsBuilder.configureActionButton(self.investButton, title: Localized(.invest))
            self.investButton.contentEdgeInsets = UIEdgeInsets(
                top: 0.0, left: self.sideInset, bottom: 0.0, right: self.sideInset
            )
            self.investButton
                .rx
                .controlEvent(.touchUpInside)
                .asDriver()
                .drive(onNext: { [weak self] in
                    let requset = Event.InvestAction.Request()
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onInvestAction(request: requset)
                    })
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupNavBarButtons() {
            self.historyButton
                .rx
                .tap
                .asDriver()
                .drive(onNext: { [weak self] in
                    let request = Event.ShowPreviousInvest.Request()
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onShowPreviousInvest(request: request)
                    })
                })
                .disposed(by: self.disposeBag)
            
            self.helpButton
                .rx
                .tap
                .asDriver()
                .drive(onNext: { [weak self] in
                    self?.routing?.onShowMessage(
                        Localized(.invest_help),
                        Localized(.invest_help_message)
                    )
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupAvailableBalanceView() {
            self.availableBalanceView.backgroundColor = Theme.Colors.contentBackgroundColor
            self.availableBalanceView.title = Localized(.available_colon)
        }
        
        private func setupEnterInvestAmountView() {
            self.enterInvestAmountView.onEnterAmount = { [weak self] (amount) in
                let request = Event.EditAmount.Request(amount: amount ?? 0.0)
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onEditAmount(request: request)
                })
            }
            
            self.enterInvestAmountView.onSelectAsset = { [weak self] in
                let request = Event.SelectBalance.Request()
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onSelectBalance(request: request)
                })
            }
        }
        
        private func setupExistingInvestmentsLabel() {
            self.existingInvestmentsLabel.backgroundColor = Theme.Colors.contentBackgroundColor
            self.existingInvestmentsLabel.text = Localized(.you_have_already_invested)
            self.existingInvestmentsLabel.textColor = Theme.Colors.separatorOnMainColor
            self.existingInvestmentsLabel.font = Theme.Fonts.smallTextFont
            self.existingInvestmentsLabel.textAlignment = .center
        }
        
        private func setupExistingInvestmentsTableView() {
            self.existingInvestmentsTableView.backgroundColor = Theme.Colors.contentBackgroundColor
            self.existingInvestmentsTableView.register(classes: [
                    SaleInvest.ExistingInvestmentCell.ViewModel.self
                ]
            )
            self.existingInvestmentsTableView.dataSource = self
            self.existingInvestmentsTableView.delegate = self
            self.existingInvestmentsTableView.estimatedRowHeight = 25.0
            self.existingInvestmentsTableView.rowHeight = UITableView.automaticDimension
            self.existingInvestmentsTableView.isUserInteractionEnabled = false
            self.existingInvestmentsTableView.separatorStyle = .none
        }
        
        private func setupLayout() {
            self.view.addSubview(self.containerView)
            self.view.addSubview(self.investButton)
            
            self.containerView.addSubview(self.investConatinerView)
            
            self.containerView.snp.makeConstraints { (make) in
                make.leading.trailing.top.equalToSuperview()
                make.bottom.equalTo(self.investButton.snp.top)
            }
            
            self.investButton.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.bottom.equalTo(self.view.safeArea.bottom)
            }
            
            self.investConatinerView.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.centerY.equalToSuperview()
            }
            
            self.layoutInvestContainerViews()
        }
        
        private func layoutInvestContainerViews() {
            self.investConatinerView.addSubview(self.availableBalanceView)
            self.investConatinerView.addSubview(self.enterInvestAmountView)
            self.investConatinerView.addSubview(self.existingInvestmentsLabel)
            self.investConatinerView.addSubview(self.existingInvestmentsTableView)
            
            self.availableBalanceView.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview()
            }
            
            self.enterInvestAmountView.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.top.equalTo(self.availableBalanceView.snp.bottom).offset(self.topInset)
            }
            
            self.existingInvestmentsLabel.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.top.equalTo(self.enterInvestAmountView.snp.bottom).offset(self.topInset)
            }
            
            self.existingInvestmentsTableView.snp.makeConstraints { (make) in
                make.leading.trailing.equalTo(self.existingInvestmentsLabel)
                make.top.equalTo(self.existingInvestmentsLabel.snp.bottom)
                make.bottom.equalToSuperview()
            }
        }
    }
}

extension SaleInvest.ViewController: SaleInvest.DisplayLogic {
    
    public func displaySceneUpdated(viewModel: Event.SceneUpdated.ViewModel) {
        self.availableBalanceView.set(
            amount: viewModel.viewModel.availableAmount,
            asset: viewModel.viewModel.selectedAsset
        )
        self.enterInvestAmountView.set(
            amount: viewModel.viewModel.inputAmount,
            asset: viewModel.viewModel.selectedAsset
        )
        self.enterInvestAmountView.set(
            amountHighlighted: viewModel.viewModel.isHighlighted
        )
        self.investButton.setTitle(viewModel.viewModel.actionTitle, for: .normal)
        self.existingInvestments = viewModel.viewModel.existingInvestment
        self.updateNavBarButtons(isCancellable: viewModel.viewModel.isCancellable)
    }
    
    public func displaySelectBalance(viewModel: Event.SelectBalance.ViewModel) {
        let assets: [String] = viewModel.balances.map({ $0.asset })
        self.routing?.onPresentPicker(assets, { [weak self] (balanceId) in
            let request = Event.BalanceSelected.Request(balanceId: balanceId)
            self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                businessLogic.onBalanceSelected(request: request)
            })
        })
    }
    
    public func displayBalanceSelected(viewModel: Event.BalanceSelected.ViewModel) {

        self.availableBalanceView.set(
            amount: viewModel.viewModel.availableAmount,
            asset: viewModel.viewModel.selectedAsset
        )
        self.enterInvestAmountView.set(
            amount: viewModel.viewModel.inputAmount,
            asset: viewModel.viewModel.selectedAsset
        )
        self.enterInvestAmountView.set(
            amountHighlighted: viewModel.viewModel.isHighlighted
        )
        self.investButton.setTitle(viewModel.viewModel.actionTitle, for: .normal)
        self.existingInvestments = viewModel.viewModel.existingInvestment
        self.updateNavBarButtons(isCancellable: viewModel.viewModel.isCancellable)
    }
    
    public func displayInvestAction(viewModel: Event.InvestAction.ViewModel) {
        switch viewModel {
            
        case .loading:
            self.routing?.onShowProgress()
            
        case .loaded:
            self.routing?.onHideProgress()
            
        case .failed(let message):
            self.routing?.onHideProgress()
            self.routing?.onShowError(message)
            
        case .succeeded(let saleInvestModel):
            self.routing?.onHideProgress()
            self.routing?.onSaleInvestAction(saleInvestModel)
        }
    }
    
    public func displayError(viewModel: Event.Error.ViewModel) {
        self.routing?.onShowError(viewModel.message)
    }
    
    public func displayEditAmount(viewModel: Event.EditAmount.ViewModel) {
        self.enterInvestAmountView.set(
            amountHighlighted: !viewModel.isAmountValid
        )
    }
    
    public func displayShowPreviousInvest(viewModel: Event.ShowPreviousInvest.ViewModel) {
        let onCanceled: (() -> Void) = { [weak self] in
            let request = Event.PrevOfferCancelled.Request()
            self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                businessLogic.onPrevOfferCanceled(request: request)
            })
        }
        self.routing?.onInvestHistory(viewModel.baseAsset, onCanceled)
    }
}

extension SaleInvest.ViewController: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.existingInvestments.isEmpty ? 0 : 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.existingInvestments.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.existingInvestments[indexPath.row]
        let cell = tableView.dequeueReusableCell(with: model, for: indexPath)
        return cell
    }
}

extension SaleInvest.ViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
}
