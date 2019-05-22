import Foundation

protocol SendPaymentPresentationLogic {
    
    typealias Event = SendPaymentAmount.Event
    
    func presentViewDidLoad(response: Event.ViewDidLoad.Response)
    func presentLoadBalances(response: Event.LoadBalances.Response)
    func presentSelectBalance(response: Event.SelectBalance.Response)
    func presentBalanceSelected(response: Event.BalanceSelected.Response)
    func presentEditAmount(response: Event.EditAmount.Response)
    func presentPaymentAction(response: Event.PaymentAction.Response)
    func presentWithdrawAction(response: Event.WithdrawAction.Response)
    func presentFeeOverviewAvailability(response: Event.FeeOverviewAvailability.Response)
    func presentFeeOverviewAction(response: Event.FeeOverviewAction.Response)
}

extension SendPaymentAmount {
    typealias PresentationLogic = SendPaymentPresentationLogic
    
    struct Presenter {
        
        typealias Model = SendPaymentAmount.Model
        typealias Event = SendPaymentAmount.Event
        
        private let presenterDispatch: PresenterDispatch
        private let amountFormatter: AmountFormatterProtocol
        
        init(
            presenterDispatch: PresenterDispatch,
            amountFormatter: AmountFormatterProtocol
            ) {
            self.presenterDispatch = presenterDispatch
            self.amountFormatter = amountFormatter
        }
        
        // MARK: - Private
        
        private func getSceneViewModel(_ sceneModel: Model.SceneModel, amountValid: Bool) -> Model.SceneViewModel {
            let sceneViewModel = Model.SceneViewModel(
                selectedBalance: self.getBalanceDetailsViewModel(sceneModel.selectedBalance),
                recipientAddress: sceneModel.recipientAddress,
                amount: sceneModel.amount,
                amountValid: amountValid
            )
            return sceneViewModel
        }
        
        private func getBalanceDetailsViewModel(
            _ balanceDetails: Model.BalanceDetails?
            ) -> Model.BalanceDetailsViewModel? {
            
            guard let balanceDetails = balanceDetails else {
                return nil
            }
            
            let viewModel = Model.BalanceDetailsViewModel(
                asset: balanceDetails.asset,
                balance: self.amountFormatter.assetAmountToString(balanceDetails.balance),
                balanceId: balanceDetails.balanceId
            )
            return viewModel
        }
    }
}

extension SendPaymentAmount.Presenter: SendPaymentAmount.PresentationLogic {
    func presentViewDidLoad(response: Event.ViewDidLoad.Response) {
        let sceneViewModel = self.getSceneViewModel(response.sceneModel, amountValid: response.amountValid)
        
        var recipientInfo = ""
        if let recipientAddress = response.sceneModel.recipientAddress {
            recipientInfo =  Localized(
                .to,
                replace: [
                    .to_replace_address: recipientAddress
                ]
            )
        }
        
        let viewModel = Event.ViewDidLoad.ViewModel(
            recipientInfo: recipientInfo,
            sceneModel: sceneViewModel
        )
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayViewDidLoad(viewModel: viewModel)
        }
    }
    
    func presentLoadBalances(response: Event.LoadBalances.Response) {
        let viewModel: Event.LoadBalances.ViewModel
        switch response {
        case .loading:
            viewModel = .loading
            
        case .loaded:
            viewModel = .loaded
            
        case .failed(let error):
            viewModel = .failed(errorMessage: error.localizedDescription)
            
        case .succeeded(let sceneModel, let amountValid):
            let sceneViewModel = self.getSceneViewModel(sceneModel, amountValid: amountValid)
            viewModel = .succeeded(sceneViewModel)
        }
        
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayLoadBalances(viewModel: viewModel)
        }
    }
    
    func presentSelectBalance(response: Event.SelectBalance.Response) {
        let balanceViewModels: [Model.BalanceDetailsViewModel] =
            response.balances.compactMap({ balanceDetails in
                return self.getBalanceDetailsViewModel(balanceDetails)
            })
        let viewModel = Event.SelectBalance.ViewModel(balances: balanceViewModels)
        self.presenterDispatch.display { displayLogic in
            displayLogic.displaySelectBalance(viewModel: viewModel)
        }
    }
    
    func presentBalanceSelected(response: Event.BalanceSelected.Response) {
        let sceneViewModel = self.getSceneViewModel(response.sceneModel, amountValid: response.amountValid)
        let viewModel = Event.BalanceSelected.ViewModel(sceneModel: sceneViewModel)
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayBalanceSelected(viewModel: viewModel)
        }
    }
    
    func presentEditAmount(response: Event.EditAmount.Response) {
        let viewModel = Event.EditAmount.ViewModel(amountValid: response.amountValid)
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayEditAmount(viewModel: viewModel)
        }
    }
    
    func presentPaymentAction(response: Event.PaymentAction.Response) {
        let viewModel: Event.PaymentAction.ViewModel
        switch response {
        case .loading:
            viewModel = .loading
            
        case .loaded:
            viewModel = .loaded
            
        case .failed(let error):
            viewModel = .failed(errorMessage: error.localizedDescription)
            
        case .succeeded(let sendModel):
            viewModel = .succeeded(sendModel)
        }
        
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayPaymentAction(viewModel: viewModel)
        }
    }
    
    func presentWithdrawAction(response: Event.WithdrawAction.Response) {
        let viewModel: Event.WithdrawAction.ViewModel
        switch response {
        case .loading:
            viewModel = .loading
            
        case .loaded:
            viewModel = .loaded
            
        case .failed(let error):
            viewModel = .failed(errorMessage: error.localizedDescription)
            
        case .succeeded(let sendModel):
            viewModel = .succeeded(sendModel)
        }
        
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayWithdrawAction(viewModel: viewModel)
        }
    }
    
    func presentFeeOverviewAvailability(response: Event.FeeOverviewAvailability.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayFeeOverviewAvailability(viewModel: viewModel)
        }
    }
    
    func presentFeeOverviewAction(response: Event.FeeOverviewAction.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayFeeOverviewAction(viewModel: viewModel)
        }
    }
}
