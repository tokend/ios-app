import Foundation

public protocol SaleInvestPresentationLogic {
    typealias Event = SaleInvest.Event
    
    func presentSceneUpdated(response: Event.SceneUpdated.Response)
    func presentSelectBalance(response: Event.SelectBalance.Response)
    func presentBalanceSelected(response: Event.BalanceSelected.Response)
    func presentInvestAction(response: Event.InvestAction.Response)
    func presentError(response: Event.Error.Response)
    func presentEditAmount(response: Event.EditAmount.Response)
    func presentShowPreviousInvest(response: Event.ShowPreviousInvest.Response)
}

extension SaleInvest {
    public typealias PresentationLogic = SaleInvestPresentationLogic
    
    @objc(SaleInvestPresenter)
    public class Presenter: NSObject {
        
        public typealias Event = SaleInvest.Event
        public typealias Model = SaleInvest.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        private let investedAmountFormatter: InvestedAmountFormatterProtocol
        private let amountFormatter: AmountFormatterProtocol
        
        // MARK: -
        
        init(
            presenterDispatch: PresenterDispatch,
            investedAmountFormatter: InvestedAmountFormatterProtocol,
            amountFormatter: AmountFormatterProtocol
            ) {
            
            self.presenterDispatch = presenterDispatch
            self.investedAmountFormatter = investedAmountFormatter
            self.amountFormatter = amountFormatter
        }
        
        // MARK: - Private
        
        private func createInvestingViewModel(
            investingModel: Model.InvestingModel
            ) -> Model.InvestingViewModel {
            
            let availableAmount = self.investedAmountFormatter
                .assetAmountToString(investingModel.availableAmount)
            
            let existingInvestments = investingModel.existingInvestment
                .map { (investment) -> SaleInvest.ExistingInvestmentCell.ViewModel in
                    let amount = self.amountFormatter.formatAmount(
                        investment.amount,
                        currency: investment.asset
                    )
                    return SaleInvest.ExistingInvestmentCell.ViewModel(
                        investmentAmount: amount
                    )
            }
            
            let isHighlighted = investingModel.amount > investingModel.availableAmount
            return Model.InvestingViewModel(
                availableAmount: availableAmount,
                inputAmount: investingModel.amount,
                selectedAsset: investingModel.selectedBalance?.asset,
                isCancellable: investingModel.isCancellable,
                actionTitle: investingModel.actionTitle,
                isHighlighted: isHighlighted,
                existingInvestment: existingInvestments
            )
        }
        
        private func getBalanceDetailsViewModel(
            _ balanceDetails: Model.BalanceDetails?
            ) -> Model.BalanceDetailsViewModel? {
            
            guard let balanceDetails = balanceDetails else {
                return nil
            }
            
            let viewModel = Model.BalanceDetailsViewModel(
                asset: balanceDetails.asset,
                balance: self.amountFormatter.formatAmount(
                    balanceDetails.balance,
                    currency: balanceDetails.asset
                ),
                balanceId: balanceDetails.balanceId
            )
            return viewModel
        }
    }
}

extension SaleInvest.Presenter: SaleInvest.PresentationLogic {
    
    public func presentSceneUpdated(response: Event.SceneUpdated.Response) {
        let ivestingViewModel = self.createInvestingViewModel(
            investingModel: response.model
        )
        let viewModel = Event.SceneUpdated.ViewModel(viewModel: ivestingViewModel)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySceneUpdated(viewModel: viewModel)
        }
    }
    
    public func presentSelectBalance(response: Event.SelectBalance.Response) {
        let balanceViewModels: [Model.BalanceDetailsViewModel] =
            response.balances.compactMap({ balanceDetails in
                return self.getBalanceDetailsViewModel(balanceDetails)
            })
        let viewModel = Event.SelectBalance.ViewModel(balances: balanceViewModels)
        self.presenterDispatch.display { displayLogic in
            displayLogic.displaySelectBalance(viewModel: viewModel)
        }
    }
    
    public func presentBalanceSelected(response: Event.BalanceSelected.Response) {
        let investViewModel = self.createInvestingViewModel(
            investingModel: response.updatedTab
        )
        let viewModel = Event.BalanceSelected.ViewModel(viewModel: investViewModel)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayBalanceSelected(viewModel: viewModel)
        }
    }
    
    public func presentInvestAction(response: Event.InvestAction.Response) {
        let viewModel: Event.InvestAction.ViewModel
        switch response {
            
        case .failed(let error):
            viewModel = .failed(errorMessage: error.localizedDescription)
            
        case .loaded:
            viewModel = .loaded
            
        case .loading:
            viewModel = .loading
            
        case .succeeded(let saleInvestModel):
            viewModel = .succeeded(saleInvestModel)
        }
        
        self.presenterDispatch.display { displayLogic in
            displayLogic.displayInvestAction(viewModel: viewModel)
        }
    }
    
    public func presentError(response: Event.Error.Response) {
        let viewModel = Event.Error.ViewModel(message: response.error.localizedDescription)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayError(viewModel: viewModel)
        }
    }
    
    public func presentEditAmount(response: Event.EditAmount.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayEditAmount(viewModel: viewModel)
        }
    }
    
    public func presentShowPreviousInvest(response: Event.ShowPreviousInvest.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayShowPreviousInvest(viewModel: viewModel)
        }
    }
}
