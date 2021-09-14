import Foundation
import RxSwift
import RxCocoa
import TokenDSDK

extension SendAmountScene {
    class FeesProvider {
        
        // MARK: - Private properties
        
        private let feesBehaviorRelay: BehaviorRelay<SendAmountScene.Model.Fees> = .init(value: .init(senderFee: 0, recipientFee: 0))
        private let loadingStatusBehaviorRelay: BehaviorRelay<SendAmountScene.Model.LoadingStatus> = .init(value: .loaded)
        
        private let feesProcessor: FeesProcessorProtocol
        fileprivate let recipientAccountId: String
        
        private var shouldObserveFees: Bool = true
        private let disposeBag: DisposeBag = .init()
        
        // MARK: -
        
        init(
            feesProcessor: FeesProcessorProtocol,
            recipientAccountId: String
        ) {
            self.feesProcessor = feesProcessor
            self.recipientAccountId = recipientAccountId
        }
    }
}

// MARK: - Private methods

private extension SendAmountScene.FeesProvider {
    
    func observeFeesProcessor() {
        feesProcessor
            .observeFees()
            .subscribe(onNext: { [weak self] (fees) in
                guard let fees = fees?.mapToFees()
                else {
                    return
                }
                self?.feesBehaviorRelay.accept(fees)
            })
            .disposed(by: disposeBag)
    }
    
    func observeFeesProcessorLoadingStatus() {
        feesProcessor
            .observeLoadingStatus()
            .subscribe(onNext: { [weak self] (loadingStatus) in
                
                if loadingStatus == .loaded {
                    self?.loadingStatusBehaviorRelay.accept(.loaded)
                } else {
                    self?.loadingStatusBehaviorRelay.accept(.loading)
                }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - Mappers

private extension FeesProcessorFeesModel {
    
    func mapToFees() -> SendAmountScene.Model.Fees {
        
        return .init(
            senderFee: self.senderFee.mapToFee(),
            recipientFee: self.recipientFee.mapToFee()
        )
    }
}

private extension Horizon.CalculatedFeeResource {
    
    func mapToFee() -> Decimal {
        
        return self.calculatedPercent + self.fixed
    }
}

// MARK: - SendAmountSceneFeesProcessorProtocol

extension SendAmountScene.FeesProvider: SendAmountScene.FeesProviderProtocol {
    var fees: SendAmountScene.Model.Fees {
        return feesBehaviorRelay.value
    }
    
    var loadingStatus: SendAmountScene.Model.LoadingStatus {
        return loadingStatusBehaviorRelay.value
    }
    
    func observeFees() -> Observable<SendAmountScene.Model.Fees> {
        if shouldObserveFees {
            shouldObserveFees = false
            observeFeesProcessor()
            observeFeesProcessorLoadingStatus()
        }
        return feesBehaviorRelay.asObservable()
    }
    
    func observeLoadingStatus() -> Observable<SendAmountScene.Model.LoadingStatus> {
        if shouldObserveFees {
            shouldObserveFees = false
            observeFeesProcessor()
            observeFeesProcessorLoadingStatus()
        }
        return loadingStatusBehaviorRelay.asObservable()
    }
    
    func processFees(
        for amount: Decimal,
        assetId: String
    ) {
        
        feesProcessor.processFees(
            for: self.recipientAccountId,
            amount: amount,
            assetId: assetId
        )
    }
}
