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
                title: "Sender fee:",
                value: senderFee
            )
            
            recipientFeeModel = .init(
                title: "Recipient fee:",
                value: recipientFee
            )
            
            if sceneModel.isPayingFeeForRecipient || fees.recipientFee > 0 {
                feeSwitcherModel = .init(
                    title: "Pay fee for recipient",
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
            enteredAmountError = "Not enoungh balance"
        case .cannotBeZero:
            enteredAmountError = "Entered amount must be more than 0"
        }
        
        return .init(
            recipientAddress: "To \(sceneModel.recipientAddress)",
            availableBalance: "Balance: \(sceneModel.selectedBalance.amount) \(sceneModel.selectedBalance.assetCode)",
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
