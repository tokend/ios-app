import RxCocoa
import RxSwift
import SnapKit
import UIKit

protocol CreateOfferDisplayLogic: class {
    typealias Event = CreateOffer.Event
    
    func displayViewDidLoadSync(viewModel: Event.ViewDidLoadSync.ViewModel)
    func displayFieldEditing(viewModel: Event.FieldEditing.ViewModel)
    func displayButtonAction(viewModel: Event.ButtonAction.ViewModel)
    func displayFieldStateDidChange(viewModel: Event.FieldStateDidChange.ViewModel)
    func displayLoadingStatusDidChange(viewModel: Event.LoadingStatusDidChange.ViewModel)
}

extension CreateOffer {
    typealias DisplayLogic = CreateOfferDisplayLogic
    
    class ViewController: UIViewController {
        typealias Event = CreateOffer.Event
        
        // MARK: - Private properties
        
        private let stackView: ScrollableStackView = ScrollableStackView()
        
        private let buttonHeight: CGFloat = 44.0
        
        private let buttonsContainerView: UIView = UIView()
        
        private let buyButton: UIButton = UIButton()
        private let sellButton: UIButton = UIButton()
        
        private let priceEnterAmountView = EnterAmountView()
        private let amountEnterAmountView = EnterAmountView()
        private let totalView = TotalView()
        
        private let disposeBag = DisposeBag()
        
        // MARK: - Injections
        
        var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        
        func inject(interactorDispatch: InteractorDispatch?, routing: Routing?) {
            self.interactorDispatch = interactorDispatch
            self.routing = routing
        }
        
        // MARK: - Overridden
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.setupView()
            self.setupFields()
            self.setupButtons()
            self.setupTotalLabel()
            self.setupLayout()
            
            let request = Event.ViewDidLoadSync.Request()
            self.interactorDispatch?.sendSyncRequest { businessLogic in
                businessLogic.onViewDidLoadSync(request: request)
            }
        }
        
        // MARK: - Private
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.contentBackgroundColor
        }
        
        private func setupFields() {
            self.amountEnterAmountView.title = Localized(.amount_colon)
            self.amountEnterAmountView.placeholder = Localized(.amount)
            self.amountEnterAmountView.onEnterAmount = { [weak self] (amount) in
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    let field = Model.Field(
                        value: amount,
                        type: .amount
                    )
                    let request = Event.FieldEditing.Request(
                        field: field
                    )
                    businessLogic.onFieldEditing(request: request)
                })
            }
            self.priceEnterAmountView.title = Localized(.price_colon)
            self.priceEnterAmountView.placeholder = Localized(.price)
            self.priceEnterAmountView.onEnterAmount = { [weak self] (amount) in
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    let field = Model.Field(
                        value: amount,
                        type: .price
                    )
                    let request = Event.FieldEditing.Request(
                        field: field
                    )
                    businessLogic.onFieldEditing(request: request)
                })
            }
        }
        
        private func setupButtons() {
            self.setupButton(
                button: self.buyButton,
                buttonModel: Model.Button(title: Localized(.buy), type: .buy)
            )
            self.setupButton(
                button: self.sellButton,
                buttonModel: Model.Button(title: Localized(.sell), type: .sell)
            )
        }
        
        private func setupTotalLabel() { }
        
        private func setupButton(button: UIButton, buttonModel: Model.Button) {
            let buttonImage = UIImage.resizableImageWithColor(Theme.Colors.actionButtonColor)
            button.setBackgroundImage(buttonImage, for: .normal)
            button.setTitle(buttonModel.title, for: .normal)
            button.setTitleColor(Theme.Colors.actionTitleButtonColor, for: .normal)
            button.titleLabel?.font = Theme.Fonts.actionButtonFont
            button
                .rx
                .controlEvent(.touchUpInside)
                .asDriver()
                .drive(onNext: { [weak self] in
                    let request = Event.ButtonAction.Request(type: buttonModel.type)
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onButtonAction(request: request)
                    })
                })
                .disposed(by: self.disposeBag)
        }
        
        private func updateTotalLabelTitle(_ value: String) {
            self.totalView.set(value: value)
        }
        
        private func setupLayout() {
            self.view.addSubview(self.stackView)
            
            self.stackView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            
            self.stackView.insert(views: [
                self.amountEnterAmountView,
                self.priceEnterAmountView,
                self.totalView,
                self.buttonsContainerView
                ])
            
            self.setupButtonsLayout()
        }
        
        private func setupButtonsLayout() {
            self.buttonsContainerView.addSubview(self.buyButton)
            self.buttonsContainerView.addSubview(self.sellButton)
            
            self.buyButton.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().inset(20)
                make.top.bottom.equalToSuperview()
                make.trailing.equalTo(self.buttonsContainerView.snp.centerX).inset(-5.0)
                make.height.equalTo(self.buttonHeight)
            }
            
            self.sellButton.snp.makeConstraints { (make) in
                make.trailing.equalToSuperview().inset(20)
                make.top.bottom.equalToSuperview()
                make.leading.equalTo(self.buttonsContainerView.snp.centerX).inset(5.0)
                make.height.equalTo(self.buttonHeight)
            }
        }
    }
}

// MARK: - CreateOfferDisplayLogicProtocol

extension CreateOffer.ViewController: CreateOffer.DisplayLogic {
    func displayViewDidLoadSync(viewModel: Event.ViewDidLoadSync.ViewModel) {
        self.priceEnterAmountView.amount = viewModel.price.value
        self.priceEnterAmountView.asset = viewModel.price.asset
        
        self.amountEnterAmountView.amount = viewModel.amount.value
        self.amountEnterAmountView.asset = viewModel.amount.asset
        
        self.updateTotalLabelTitle(viewModel.total)
    }
    
    func displayFieldEditing(viewModel: Event.FieldEditing.ViewModel) {
        self.updateTotalLabelTitle(viewModel.total)
    }
    
    func displayButtonAction(viewModel: Event.ButtonAction.ViewModel) {
        switch viewModel {
        case .offer(let offer):
            self.routing?.onAction(offer)
        case .error(let error):
            self.routing?.onShowError(error)
        }
    }
    
    func displayFieldStateDidChange(viewModel: Event.FieldStateDidChange.ViewModel) {
        self.priceEnterAmountView.set(amountHighlighted: viewModel.priceTextFieldState == .error)
        self.amountEnterAmountView.set(amountHighlighted: viewModel.amountTextFieldState == .error)
    }
    
    func displayLoadingStatusDidChange(viewModel: Event.LoadingStatusDidChange.ViewModel) {
        switch viewModel {
            
        case .loaded:
            self.routing?.hideProgress()
            
        case .loading:
            self.routing?.showProgress()
        }
    }
}
