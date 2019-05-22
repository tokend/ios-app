import Foundation
import TokenDSDK
import RxSwift
import RxCocoa

protocol SendPaymentAmountFeeOverviewerProtocol {
    func observeErrors() -> Observable<Swift.Error>
    func checkFeeExistanceFor(
        asset: String,
        feeType: SendPaymentAmount.Model.FeeType
        ) -> Bool
    func getSystemFeeType(feeType: SendPaymentAmount.Model.FeeType) -> Int32
}

extension SendPaymentAmount {
    typealias FeeOverviewerProtocol = SendPaymentAmountFeeOverviewerProtocol
    
    class FeeOverviewer {
        
        // MARK: - Private properties
        
        private let generalApi: GeneralApi
        private let accountId: String
        private var feeOverviews: [String: [FeeResponse]] = [:]
        private let errors: PublishRelay<Swift.Error> = PublishRelay()
        
        // MARK: -
        
        init(
            generalApi: GeneralApi,
            accountId: String
            ) {
            
            self.generalApi = generalApi
            self.accountId = accountId
            
            self.fetchOverviews()
        }
        
        // MARK: - Private
        
        private func fetchOverviews() {
            self.generalApi.requestFeesOverview { [weak self] (result) in
                switch result {
                    
                case .failed(let errors):
                    self?.errors.accept(errors)
                    
                case .succeeded(let response):
                    self?.feeOverviews = response.fees
                }
            }
        }
        
        private func feeTypeForFeeType(_ type: Model.FeeType) -> FeeResponse.FeeType {
            switch type {
                
            case .payment:
                return .paymentFee
                
            case .offer:
                return .offerFee
                
            case .withdraw:
                return .withdrawalFee
            }
        }
    }
}

extension SendPaymentAmount.FeeOverviewer: SendPaymentAmount.FeeOverviewerProtocol {
    
    func observeErrors() -> Observable<Error> {
        return self.errors.asObservable()
    }
    
    func checkFeeExistanceFor(
        asset: String,
        feeType: SendPaymentAmount.Model.FeeType
        ) -> Bool {
        
        let type = self.feeTypeForFeeType(feeType).rawValue
        
        return self.feeOverviews.contains (where: { (feeAsset, fees) -> Bool in
            return asset == feeAsset && fees.contains(where: { (fee) -> Bool in
                fee.feeType == type && (fee.accountId == accountId || fee.accountId.isEmpty)
            })
        })
    }
    
    func getSystemFeeType(feeType: SendPaymentAmount.Model.FeeType) -> Int32 {
        return self.feeTypeForFeeType(feeType).rawValue
    }
}
