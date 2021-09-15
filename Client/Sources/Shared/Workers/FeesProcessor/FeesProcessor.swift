import Foundation
import TokenDSDK
import TokenDWallet
import RxSwift
import RxCocoa

class FeesProcessor {
    
    // MARK: - Private properties
    
    private let feesApi: FeesApiV3
    private let debounceWorker: DebounceWorkerProtocol = DebounceWorker()
    
    private var latestFees: FeesProcessorFeesModel? = nil

    fileprivate let originalAccountId: String
    
    private var senderCancelable: TokenDSDK.Cancelable? = nil
    private var recipientCancelable: TokenDSDK.Cancelable? = nil
    
    // MARK: -
    
    init(
        originalAccountId: String,
        feesApi: FeesApiV3
    ) {
        self.originalAccountId = originalAccountId
        self.feesApi = feesApi
    }
}

// MARK: - Private methods

private extension FeesProcessor {
    
    func fetchFees(
        for recipientAccountId: String,
        amount: Decimal,
        assetId: String,
        completion: @escaping (Result<FeesProcessorFeesModel, Swift.Error>) -> Void
    ) {
        
        senderCancelable?.cancel()
        recipientCancelable?.cancel()
                
        var senderFee: Horizon.CalculatedFeeResource?
        var recipientFee: Horizon.CalculatedFeeResource?
        
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
            for: recipientAccountId,
            amount: amount,
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
                    self.latestFees = nil
                    completion(.failure(FeesProcessorError.failedToFetchFees))
                    return
                }
                
                let fees: FeesProcessorFeesModel = .init(
                    senderFee: senderFee,
                    recipientFee: recipientFee
                )
                
                self.latestFees = fees
                completion(.success(fees))
            }
        )
    }
    
    func fetchSenderFee(
        for amount: Decimal,
        assetId: String,
        completion: @escaping (Swift.Result<Horizon.CalculatedFeeResource, Swift.Error>) -> Void
    ) {
        
        senderCancelable = feesApi.getCalculatedFees(
            for: self.originalAccountId,
            assetId: assetId,
            amount: amount,
            feeType: Int(FeeType.paymentFee.rawValue),
            subtype: Int(PaymentFeeType.outgoing.rawValue),
            completion: { (result) in
                
                switch result {
                
                case .success(let resource):
                    
                    guard let data = resource.data
                    else {
                        completion(.failure(FeesProcessorError.noData))
                        return
                    }
                    
                    completion(.success(data))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        )
    }
    
    func fetchRecipientFee(
        for recipientAccountId: String,
        amount: Decimal,
        assetId: String,
        completion: @escaping (Swift.Result<Horizon.CalculatedFeeResource, Swift.Error>) -> Void
    ) {
        
        recipientCancelable = feesApi.getCalculatedFees(
            for: recipientAccountId,
            assetId: assetId,
            amount: amount,
            feeType: Int(FeeType.paymentFee.rawValue),
            subtype: Int(PaymentFeeType.incoming.rawValue),
            completion: { (result) in
                
                switch result {
                
                case .success(let resource):
                    
                    guard let data = resource.data
                    else {
                        completion(.failure(FeesProcessorError.noData))
                        return
                    }
                    
                    completion(.success(data))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        )
    }
}

// MARK: - FeesProcessorProtocol

extension FeesProcessor: FeesProcessorProtocol {
    
    var fees: FeesProcessorFeesModel? {
        return latestFees
    }
    
    func processFees(
        for recipientAccountId: String,
        amount: Decimal,
        assetId: String,
        completion: @escaping (Result<FeesProcessorFeesModel, Swift.Error>) -> Void
    ) {
        
        debounceWorker.debounce(
            delay: 0.5,
            completion: { [weak self] in
                self?.fetchFees(
                    for: recipientAccountId,
                    amount: amount,
                    assetId: assetId,
                    completion: completion
                )
            }
        )
    }
}
