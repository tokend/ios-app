import Foundation

protocol SendPaymentPresentationLogic {
    func presentViewDidLoad(response: SendPayment.Event.ViewDidLoad.Response)
    func presentLoadBalances(response: SendPayment.Event.LoadBalances.Response)
    func presentSelectBalance(response: SendPayment.Event.SelectBalance.Response)
    func presentBalanceSelected(response: SendPayment.Event.BalanceSelected.Response)
    func presentScanRecipientQRAddress(response: SendPayment.Event.ScanRecipientQRAddress.Response)
    func presentEditAmount(response: SendPayment.Event.EditAmount.Response)
    func presentPaymentAction(response: SendPayment.Event.PaymentAction.Response)
    func presentWithdrawAction(response: SendPayment.Event.WithdrawAction.Response)
}

extension SendPayment {
    typealias PresentationLogic = SendPaymentPresentationLogic
    
    struct Presenter {
        
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

extension SendPayment.Presenter: SendPayment.PresentationLogic {
    func presentViewDidLoad(response: SendPayment.Event.ViewDidLoad.Response) {
        let sceneViewModel = self.getSceneViewModel(response.sceneModel, amountValid: response.amountValid)
        let viewModel = SendPayment.Event.ViewDidLoad.ViewModel(sceneModel: sceneViewModel)
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayViewDidLoad(viewModel: viewModel)
        }
    }
    
    func presentLoadBalances(response: SendPayment.Event.LoadBalances.Response) {
        let viewModel: SendPayment.Event.LoadBalances.ViewModel
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
    
    func presentSelectBalance(response: SendPayment.Event.SelectBalance.Response) {
        let balanceViewModels: [SendPayment.Model.BalanceDetailsViewModel] =
            response.balances.compactMap({ balanceDetails in
                return self.getBalanceDetailsViewModel(balanceDetails)
            })
        let viewModel = SendPayment.Event.SelectBalance.ViewModel(balances: balanceViewModels)
        self.presenterDispatch.display { displayLogic in
            displayLogic.displaySelectBalance(viewModel: viewModel)
        }
    }
    
    func presentBalanceSelected(response: SendPayment.Event.BalanceSelected.Response) {
        let sceneViewModel = self.getSceneViewModel(response.sceneModel, amountValid: response.amountValid)
        let viewModel = SendPayment.Event.BalanceSelected.ViewModel(sceneModel: sceneViewModel)
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayBalanceSelected(viewModel: viewModel)
        }
    }
    
    func presentScanRecipientQRAddress(response: SendPayment.Event.ScanRecipientQRAddress.Response) {
        let viewModel: SendPayment.Event.ScanRecipientQRAddress.ViewModel
        switch response {
        case .canceled:
            viewModel = .canceled
            
        case .failed(let error):
            viewModel = .failed(errorMessage: error.localizedDescription)
            
        case .succeeded(let sceneModel, let amountValid):
            let sceneViewModel = self.getSceneViewModel(sceneModel, amountValid: amountValid)
            viewModel = .succeeded(sceneViewModel)
        }
        
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayScanRecipientQRAddress(viewModel: viewModel)
        }
    }
    
    func presentEditAmount(response: SendPayment.Event.EditAmount.Response) {
        let viewModel = SendPayment.Event.EditAmount.ViewModel(amountValid: response.amountValid)
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayEditAmount(viewModel: viewModel)
        }
    }
    
    func presentPaymentAction(response: SendPayment.Event.PaymentAction.Response) {
        let viewModel: SendPayment.Event.PaymentAction.ViewModel
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
    
    func presentWithdrawAction(response: SendPayment.Event.WithdrawAction.Response) {
        let viewModel: SendPayment.Event.WithdrawAction.ViewModel
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
}
