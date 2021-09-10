import Foundation
import RxSwift
import RxCocoa

public protocol SendAmountSceneBusinessLogic {
    
    typealias Event = SendAmountScene.Event
    
    func onViewDidLoad(request: Event.ViewDidLoad.Request)
    func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request)
    func onDidEnterAmountSync(request: Event.DidEnterAmountSync.Request)
    func onDidEnterDescriptionSync(request: Event.DidEnterDescriptionSync.Request)
    func onDidSwitchPayFeeForRecipientSync(request: Event.DidSwitchPayFeeForRecipientSync.Request)
    func onDidTapContinueSync(request: Event.DidTapContinueSync.Request)
}

extension SendAmountScene {
    
    public typealias BusinessLogic = SendAmountSceneBusinessLogic
    
    @objc(SendAmountSceneInteractor)
    public class Interactor: NSObject {
        
        public typealias Event = SendAmountScene.Event
        public typealias Model = SendAmountScene.Model
        
        // MARK: - Private properties
        
        private let presenter: PresentationLogic
        private var sceneModel: Model.SceneModel
        private let selectedBalanceProvider: SelectedBalanceProviderProtocol
        private let feesProcessor: FeesProcessorProtocol

        private let disposeBag: DisposeBag = .init()
        
        // MARK: -
        
        public init(
            presenter: PresentationLogic,
            recipientAddress: String,
            selectedBalanceProvider: SelectedBalanceProviderProtocol,
            feesProcessor: FeesProcessorProtocol
        ) {
            
            self.presenter = presenter
            self.selectedBalanceProvider = selectedBalanceProvider
            self.feesProcessor = feesProcessor
            
            self.sceneModel = .init(
                selectedBalance: selectedBalanceProvider.selectedBalance,
                recipientAddress: recipientAddress,
                description: nil,
                enteredAmount: nil,
                enteredAmountError: nil,
                feesForEnteredAmount: feesProcessor.fees,
                isPayingFeeForRecipient: false,
                feesLoadingStatus: .loaded
            )
        }
    }
}

// MARK: - Private methods

private extension SendAmountScene.Interactor {
    
    func presentSceneDidUpdate(animated: Bool) {
        let response: Event.SceneDidUpdate.Response = .init(
            sceneModel: sceneModel,
            animated: animated
        )
        presenter.presentSceneDidUpdate(response: response)
    }

    func presentSceneDidUpdateSync(animated: Bool) {
        let response: Event.SceneDidUpdateSync.Response = .init(
            sceneModel: sceneModel,
            animated: animated
        )
        presenter.presentSceneDidUpdateSync(response: response)
    }
    
    func validateEnteredAmount() -> Model.EnteredAmountValidationError? {
        
        guard let enteredAmount = sceneModel.enteredAmount
        else {
            return .emptyString
        }
        
        guard enteredAmount != 0
        else {
            return .cannotBeZero
        }
        
        guard enteredAmount <= sceneModel.selectedBalance.amount
        else {
            return .notEnoughBalance
        }
        
        return nil
    }
    
    func observeSelectedBalance() {
        selectedBalanceProvider
            .observeBalance()
            .subscribe(onNext: { [weak self] (balance) in
                self?.sceneModel.selectedBalance = balance
                self?.presentSceneDidUpdate(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    func observeFees() {
        feesProcessor
            .observeFees()
            .subscribe(onNext: { [weak self] (fees) in
                self?.sceneModel.feesForEnteredAmount = fees
                self?.presentSceneDidUpdate(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    func observeFeesLoadingStatus() {
        feesProcessor
            .observeLoadingStatus()
            .subscribe(onNext: { [weak self] (loadingStatus) in
                self?.sceneModel.feesLoadingStatus = loadingStatus
                self?.presentSceneDidUpdate(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    func processFeesForEnteredAmount() {
        
//        guard validateEnteredAmount() == nil,
//            let enteredAmount = sceneModel.enteredAmount
//        else {
//            return
//        }
        
        feesProcessor.processFees(
            for: sceneModel.enteredAmount ?? 0,
            assetId: sceneModel.selectedBalance.assetCode
        )
    }
}

// MARK: - BusinessLogic

extension SendAmountScene.Interactor: SendAmountScene.BusinessLogic {
    
    public func onViewDidLoad(request: Event.ViewDidLoad.Request) {
        observeSelectedBalance()
        observeFees()
        observeFeesLoadingStatus()
    }
    
    public func onViewDidLoadSync(request: Event.ViewDidLoadSync.Request) {
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidEnterAmountSync(request: Event.DidEnterAmountSync.Request) {
        sceneModel.enteredAmount = request.value
        sceneModel.enteredAmountError = validateEnteredAmount()
        processFeesForEnteredAmount()
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidEnterDescriptionSync(request: Event.DidEnterDescriptionSync.Request) {
        sceneModel.description = request.value
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidSwitchPayFeeForRecipientSync(request: Event.DidSwitchPayFeeForRecipientSync.Request) {
        sceneModel.isPayingFeeForRecipient = request.value
        presentSceneDidUpdateSync(animated: false)
    }
    
    public func onDidTapContinueSync(request: Event.DidTapContinueSync.Request) {
        
    }
}
