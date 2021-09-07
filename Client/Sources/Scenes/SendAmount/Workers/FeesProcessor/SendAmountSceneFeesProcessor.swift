import Foundation
import RxSwift
import RxCocoa
import TokenDSDK

extension SendAmountScene {
    class FeesProcessor {
        
        // MARK: - Private properties
        
        private let feesBehaviorRelay: BehaviorRelay<[Decimal: SendAmountScene.Model.Fees]> = .init(value: [:])
        private let loadingStatusBehaviorRelay: BehaviorRelay<SendAmountScene.Model.LoadingStatus> = .init(value: .loaded)
        private let feesApi: FeesApiV3
        
        fileprivate let originalAccountId: String
        fileprivate let recipientAccountId: String
        
        // MARK: -
        
        init(
            originalAccountId: String,
            recipientAccountId: String,
            feesApi: FeesApiV3
        ) {
            self.originalAccountId = originalAccountId
            self.recipientAccountId = recipientAccountId
            self.feesApi = feesApi
        }
    }
}

// MARK: - Private methods

private extension SendAmountScene.FeesProcessor {
    
    func fetchSenderFee(
        for amount: Decimal,
        assetId: String,
        completion: @escaping (Swift.Result<Decimal, Swift.Error>) -> Void
    ) {
        
        feesApi.getCalculatedFees(
            for: self.originalAccountId,
            assetId: assetId,
            amount: amount,
            feeType: 0,
            subtype: 1,
            completion: { (result) in
                
                switch result {
                
                case .success(let resource):
                    
                    guard let data = resource.data
                    else {
                        // TODO: - set completion
                        return
                    }
                    
                    completion(.success(data.mapToFee()))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        )
    }
    
    func fetchRecipientFee(
        for amount: Decimal,
        assetId: String,
        completion: @escaping (Swift.Result<Decimal, Swift.Error>) -> Void
    ) {
        
        feesApi.getCalculatedFees(
            for: self.recipientAccountId,
            assetId: assetId,
            amount: amount,
            feeType: 0,
            subtype: 2,
            completion: { (result) in
                
                switch result {
                
                case .success(let resource):
                    
                    guard let data = resource.data
                    else {
                        // TODO: - set completion
                        return
                    }
                    
                    completion(.success(data.mapToFee()))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        )
    }
    
    func updateValue(
        for amount: Decimal,
        value: SendAmountScene.Model.Fees
    ) {
        var fees = feesBehaviorRelay.value
        fees[amount] = value
        feesBehaviorRelay.accept(fees)
    }
}

// MARK: - Mappers

private extension Horizon.CalculatedFeeResource {
    
    func mapToFee() -> Decimal {
        
        return self.calculatedPercent + self.fixed
    }
}

// MARK: - SendAmountSceneFeesProcessorProtocol

extension SendAmountScene.FeesProcessor: SendAmountScene.FeesProcessorProtocol {
    var feesList: [Decimal: SendAmountScene.Model.Fees] {
        return feesBehaviorRelay.value
    }
    
    var loadingStatus: SendAmountScene.Model.LoadingStatus {
        return loadingStatusBehaviorRelay.value
    }
    
    func observeFees() -> Observable<[Decimal: SendAmountScene.Model.Fees]> {
        return feesBehaviorRelay.asObservable()
    }
    
    func observeLoadingStatus() -> Observable<SendAmountScene.Model.LoadingStatus> {
        return loadingStatusBehaviorRelay.asObservable()
    }
    
    func processFees(
        for amount: Decimal,
        assetId: String
    ) {
        
        if feesBehaviorRelay.value[amount] != nil {
            return
        }
        
        var senderFee: Decimal?
        var recipientFee: Decimal?
        
        loadingStatusBehaviorRelay.accept(.loading)
        let group: DispatchGroup = .init()
        group.enter()
        
        group.enter()
        self.fetchSenderFee(
            for: amount,
            assetId: assetId,
            completion: { (result) in
                
                switch result {
                
                case .success(let fee):
                    senderFee = fee
                case .failure:
                    senderFee = nil
                }
                
                group.leave()
            }
        )
        
        group.enter()
        self.fetchRecipientFee(
            for: amount,
            assetId: assetId,
            completion: { (result) in
                
                switch result {
                
                case .success(let fee):
                    recipientFee = fee
                case .failure:
                    recipientFee = nil
                }
                
                group.leave()
            }
        )
        
        group.leave()
        group.notify(
            queue: .main,
            execute: {
                
                guard let senderFee = senderFee,
                      let recipientFee = recipientFee
                else {
                    print(.log(message: "Error while fetching fees"))
                    return
                }
                
                let fees: SendAmountScene.Model.Fees = .init(
                    senderFee: senderFee,
                    recipientFee: recipientFee
                )
                
                self.updateValue(for: amount, value: fees)
                
                self.loadingStatusBehaviorRelay.accept(.loaded)
            }
        )
    }
}
