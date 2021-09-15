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
        return feesBehaviorRelay.asObservable()
    }
    
    func observeLoadingStatus() -> Observable<SendAmountScene.Model.LoadingStatus> {
        return loadingStatusBehaviorRelay.asObservable()
    }
    
    func calculateFees(
        for amount: Decimal,
        assetId: String
    ) {
        
        loadingStatusBehaviorRelay.accept(.loading)
        
        feesProcessor.processFees(
            for: self.recipientAccountId,
            amount: amount,
            assetId: assetId,
            completion: { [weak self] (result) in
                
                switch result {
                
                case .success(let fees):
                    self?.feesBehaviorRelay.accept(fees.mapToFees())
                case .failure:
                    // TODO: - Handle errors
                    break
                }
                
                self?.loadingStatusBehaviorRelay.accept(.loaded)
            }
        )
    }
}
