import Foundation

public protocol SendAmountScenePresentationLogic {
    
    typealias Event = SendAmountScene.Event
    
    func presentSceneDidUpdate(response: Event.SceneDidUpdate.Response)
    func presentSceneDidUpdateSync(response: Event.SceneDidUpdateSync.Response)
    func presentDidTapContinueSync(response: Event.DidTapContinueSync.Response)
}

extension SendAmountScene {
    
    public typealias PresentationLogic = SendAmountScenePresentationLogic
    
    @objc(SendAmountScenePresenter)
    public class Presenter: NSObject {
        
        public typealias Event = SendAmountScene.Event
        public typealias Model = SendAmountScene.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        private let numberFormatter: NumberFormatter = {
            
            let formatter = NumberFormatter()
            formatter.usesGroupingSeparator = false
            formatter.decimalSeparator = NumberFormatter().decimalSeparator ?? Locale.current.decimalSeparator ?? "."
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 1
            formatter.minimumIntegerDigits = 1
            formatter.maximumFractionDigits = 8
            return formatter
        }()
        
        // MARK: -
        
        public init(
            presenterDispatch: PresenterDispatch
        ) {
            
            self.presenterDispatch = presenterDispatch
        }
    }
}

// MARK: - Private methods

private extension SendAmountScene.Presenter {
    
    func mapSceneModel(_ sceneModel: Model.SceneModel) -> Model.SceneViewModel {
        
        let navigationBarTitle: String = Localized(
            .send_amount_navigation_bar_title,
            replace: [
                .send_amount_navigation_bar_title_replace_asset: sceneModel.selectedBalance.assetCode
            ]
        )
        let recipientAddress: String = Localized(
            .send_amount_recipient_address,
            replace: [
                .send_amount_recipient_address_replace_address: sceneModel.recipientAddress
            ]
        )
        
        let balance: String = "\(sceneModel.selectedBalance.amount) \(sceneModel.selectedBalance.assetCode)"
        let availableBalance: String = Localized(
            .send_amount_available_balance,
            replace: [
                .send_amount_available_balance_replace_amount: balance
            ]
        )
                
        let senderFeeModel: FeeAmountView.ViewModel?
        let recipientFeeModel: FeeAmountView.ViewModel?
        let feeSwitcherModel: FeeSwitcherView.ViewModel?
        
        if let fees = sceneModel.feesForEnteredAmount {
            
            let senderFee: String
            let recipientFee: String
            
            // TODO: - Add amount formatter
            
            if sceneModel.enteredAmount == 0 {
                senderFee = "0"
                recipientFee = "0"
            } else if sceneModel.isPayingFeeForRecipient {
                senderFee = "\(fees.senderFee + fees.recipientFee)"
                recipientFee = "0"
            } else {
                senderFee = "\(fees.senderFee)"
                recipientFee = "\(fees.recipientFee)"
            }
            
            senderFeeModel = .init(
                title: Localized(.send_amount_sender_fee),
                value: senderFee
            )
            
            recipientFeeModel = .init(
                title: Localized(.send_amount_recipient_fee),
                value: recipientFee
            )
            
            if sceneModel.isPayingFeeForRecipient || fees.recipientFee > 0 {
                feeSwitcherModel = .init(
                    title: Localized(.send_amount_pay_fee_for_recipient),
                    switcherValue: sceneModel.isPayingFeeForRecipient
                )
            } else {
                feeSwitcherModel = nil
            }
        } else {
            senderFeeModel = nil
            recipientFeeModel = nil
            feeSwitcherModel = nil
        }
        
        let enteredAmountError: String?
        
        switch sceneModel.enteredAmountError {
        
        case .none:
            enteredAmountError = nil
        case .emptyString:
            enteredAmountError = Localized(.validation_error_empty)
        case .notEnoughBalance:
            enteredAmountError = Localized(.send_amount_error_not_enough_balance)
        case .cannotBeZero:
            enteredAmountError = Localized(.send_amount_error_cannot_be_zero)
        }
        
        return .init(
            navigationBarTitle: navigationBarTitle,
            recipientAddress: recipientAddress,
            availableBalance: availableBalance,
            amountContext: .init(formatter: numberFormatter),
            enteredAmount: sceneModel.enteredAmount,
            enteredAmountError: enteredAmountError,
            assetCode: sceneModel.selectedBalance.assetCode,
            description: sceneModel.description,
            senderFeeModel: senderFeeModel,
            recipientFeeModel: recipientFeeModel,
            feeSwitcherModel: feeSwitcherModel,
            feeIsLoading: sceneModel.feesLoadingStatus == .loading
        )
    }
}

// MARK: - PresenterLogic

extension SendAmountScene.Presenter: SendAmountScene.PresentationLogic {
    
    public func presentSceneDidUpdate(response: Event.SceneDidUpdate.Response) {
        let viewModel = mapSceneModel(response.sceneModel)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySceneDidUpdate(
                viewModel: .init(
                    viewModel: viewModel,
                    animated: response.animated
                )
            )
        }
    }
    
    public func presentSceneDidUpdateSync(response: Event.SceneDidUpdateSync.Response) {
        let viewModel = mapSceneModel(response.sceneModel)
        self.presenterDispatch.displaySync { (displayLogic) in
            displayLogic.displaySceneDidUpdateSync(
                viewModel: .init(
                    viewModel: viewModel,
                    animated: response.animated
                )
            )
        }
    }
    
    public func presentDidTapContinueSync(response: Event.DidTapContinueSync.Response) {
        let viewModel: Event.DidTapContinueSync.ViewModel = response
        self.presenterDispatch.displaySync { (displayLogic) in
            displayLogic.displayDidTapContinueSync(viewModel: viewModel)
        }
    }
}
