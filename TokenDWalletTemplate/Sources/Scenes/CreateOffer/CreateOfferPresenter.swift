import Foundation

protocol CreateOfferPresentationLogic {
    func presentViewDidLoadSync(response: CreateOffer.Event.ViewDidLoadSync.Response)
    func presentFieldEditing(response: CreateOffer.Event.FieldEditing.Response)
    func presentButtonAction(response: CreateOffer.Event.ButtonAction.Response)
    func presentFieldStateDidChange(response: CreateOffer.Event.FieldStateDidChange.Response)
}

extension CreateOffer {
    typealias PresentationLogic = CreateOfferPresentationLogic
    
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
        
        private func stringFromTotal(
            _ total: Model.Amount
            ) -> String {
            
            return self.amountFormatter.formatTotal(total)
        }
    }
}

extension CreateOffer.Presenter: CreateOffer.PresentationLogic {
    func presentViewDidLoadSync(response: CreateOffer.Event.ViewDidLoadSync.Response) {
        let viewModel = CreateOffer.Event.ViewDidLoadSync.ViewModel(
            price: response.price,
            amount: response.amount,
            total: self.stringFromTotal(response.total)
        )
        self.presenterDispatch.displaySync { displayLogic in
            displayLogic.displayViewDidLoadSync(viewModel: viewModel)
        }
    }
    
    func presentFieldEditing(response: CreateOffer.Event.FieldEditing.Response) {
        let viewModel = CreateOffer.Event.FieldEditing.ViewModel(
            total: self.stringFromTotal(response.total)
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayFieldEditing(viewModel: viewModel)
        }
    }
    
    func presentButtonAction(response: CreateOffer.Event.ButtonAction.Response) {
        let viewModel = response
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayButtonAction(viewModel: viewModel)
        }
    }
    
    func presentFieldStateDidChange(response: CreateOffer.Event.FieldStateDidChange.Response) {
        let viewModel = CreateOffer.Event.FieldStateDidChange.ViewModel(
            priceTextFieldState: self.loadTextFieldState(isFilled: response.priceFieldIsFilled),
            amountTextFieldState: self.loadTextFieldState(isFilled: response.amountFieldIsFilled)
        )
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayFieldStateDidChange(viewModel: viewModel)
        }
    }
}

extension CreateOffer.Presenter {
    typealias TextFieldState = CreateOffer.Event.FieldStateDidChange.ViewModel.TextFieldState
    
    func loadTextFieldState(isFilled: Bool) -> TextFieldState {
        if isFilled {
            return .normal
        } else {
            return .error
        }
    }
}
