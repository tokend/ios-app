import Foundation
import RxSwift
import RxCocoa
import TokenDSDK

extension SendAmountScene {
    class FeesProcessor {
        
        // MARK: - Private properties
        
        private let feesBehaviorRelay: BehaviorRelay<SendAmountScene.Model.Fees> = .init(value: .init(senderFee: 0, recipientFee: 0))
        private let loadingStatusBehaviorRelay: BehaviorRelay<SendAmountScene.Model.LoadingStatus> = .init(value: .loaded)
        private let feesApi: FeesApiV3
        
        private let debouncer: Debouncer = .init()
        
        fileprivate let originalAccountId: String
        fileprivate let recipientAccountId: String
        
        private var senderCancelable: TokenDSDK.Cancelable? = nil
        private var recipientCancelable: TokenDSDK.Cancelable? = nil
        
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
    
    func fetchFees(
        for amount: Decimal,
        assetId: String
    ) {
        
        senderCancelable?.cancel()
        recipientCancelable?.cancel()
        
        loadingStatusBehaviorRelay.accept(.loading)
        
        var senderFee: Decimal?
        var recipientFee: Decimal?
        
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
                    print(.debug(message: "Error while fetching fees"))
                    return
                }
                
                let fees: SendAmountScene.Model.Fees = .init(
                    senderFee: senderFee,
                    recipientFee: recipientFee
                )
                
                self.feesBehaviorRelay.accept(fees)
                self.loadingStatusBehaviorRelay.accept(.loaded)
            }
        )
    }
    
    func fetchSenderFee(
        for amount: Decimal,
        assetId: String,
        completion: @escaping (Swift.Result<Decimal, Swift.Error>) -> Void
    ) {
        
        senderCancelable = feesApi.getCalculatedFees(
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
                        completion(.failure(SendAmountSceneFeesProcessorError.noData))
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
        
        recipientCancelable = feesApi.getCalculatedFees(
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
                        completion(.failure(SendAmountSceneFeesProcessorError.noData))
                        return
                    }
                    
                    completion(.success(data.mapToFee()))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        )
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
    
    func processFees(
        for amount: Decimal,
        assetId: String
    ) {
        print(.debug(message: "Initiated debounce"))
        debouncer.debounce(
            delay: 0.5,
            completion: { [weak self] in
                print(.debug(message: "Debounce"))
                self?.fetchFees(
                    for: amount,
                    assetId: assetId
                )
            }
        )
    }
}
