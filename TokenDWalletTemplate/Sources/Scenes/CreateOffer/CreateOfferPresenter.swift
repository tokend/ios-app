import Foundation

protocol CreateOfferPresentationLogic {
    typealias Event = CreateOffer.Event
    
    func presentViewDidLoadSync(response: Event.ViewDidLoadSync.Response)
    func presentFieldEditing(response: Event.FieldEditing.Response)
    func presentButtonAction(response: Event.ButtonAction.Response)
    func presentFieldStateDidChange(response: Event.FieldStateDidChange.Response)
    func presentLoadingStatusDidChange(response: Event.LoadingStatusDidChange.Response)
}

extension CreateOffer {
    typealias PresentationLogic = CreateOfferPresentationLogic
    
    struct Presenter {
        typealias Event = CreateOffer.Event
        
        private let presenterDispatch: PresenterDispatch
        private let amountFormatter: AmountFormatterProtocol
        
        init(
            presenterDispatch: PresenterDispatch,
            amountFormatter: AmountFormatterProtocol
            ) {
            
            self.presenterDispatch = presenterDispatch
            self.amountFormatter = amountFormatter
        }
        
        private func stringFromTotal(
            _ total: Model.Amount
            ) -> String {
            
            return self.amountFormatter.formatTotal(total)
        }
    }
}

extension CreateOffer.Presenter: CreateOffer.PresentationLogic {
    func presentViewDidLoadSync(response: Event.ViewDidLoadSync.Response) {
        let viewModel = Event.ViewDidLoadSync.ViewModel(
            price: response.price,
            amount: response.amount,
            total: self.stringFromTotal(response.total)
        )
        self.presenterDispatch.displaySync { displayLogic in
            displayLogic.displayViewDidLoadSync(viewModel: viewModel)
        }
    }
    
    func presentFieldEditing(response: Event.FieldEditing.Response) {
        let viewModel = Event.FieldEditing.ViewModel(
            total: self.stringFromTotal(response.total)
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayFieldEditing(viewModel: viewModel)
        }
    }
    
    func presentButtonAction(response: Event.ButtonAction.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayButtonAction(viewModel: viewModel)
        }
    }
    
    func presentFieldStateDidChange(response: Event.FieldStateDidChange.Response) {
        let viewModel = Event.FieldStateDidChange.ViewModel(
            priceTextFieldState: self.loadTextFieldState(isFilled: response.priceFieldIsFilled),
            amountTextFieldState: self.loadTextFieldState(isFilled: response.amountFieldIsFilled)
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayFieldStateDidChange(viewModel: viewModel)
        }
    }
    
    public func presentLoadingStatusDidChange(response: Event.LoadingStatusDidChange.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayLoadingStatusDidChange(viewModel: viewModel)
        }
    }
}

extension CreateOffer.Presenter {
    typealias TextFieldState = Event.FieldStateDidChange.ViewModel.TextFieldState
    
    func loadTextFieldState(isFilled: Bool) -> TextFieldState {
        if isFilled {
            return .normal
        } else {
            return .error
        }
    }
}
